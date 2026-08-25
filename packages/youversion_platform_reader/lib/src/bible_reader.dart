import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

import 'controllers/bible_reader_controller.dart';
import 'highlights/pending_highlight_queue.dart';
import 'l10n/youversion_reader_strings.dart';
import 'screens/font_settings_sheet.dart';
import 'screens/references_screen.dart';
import 'settings/reader_settings_storage.dart';
import 'storage/youversion_reader_storage.dart';
import 'theme/reading_theme_scope.dart';

/// Full Bible-reading screen: header (version + font button + sign-in
/// status), scripture body with tap-to-select-a-verse, bottom chapter
/// navigation, verse-action sheet on selection, and font/theme-settings
/// sheet.
///
/// Every API client is **injected**, never created internally - same
/// dependency-injection split used throughout this monorepo. This widget
/// composes `youversion_platform_ui` widgets and `youversion_platform_core`
/// clients; it owns no network/auth logic of its own beyond wiring them
/// together. Mirrors `platform-reader`'s `BibleReader.kt` (Kotlin) /
/// `BibleReaderView.swift` (Swift) / React's `bible-reader.tsx` compound
/// component.
class BibleReader extends StatefulWidget {
  const BibleReader({
    super.key,
    required this.content,
    required this.bible,
    required this.index,
    required this.initialChapterId,
    required this.storage,
    this.highlightsClient,
    this.userAccessToken,
    this.onSignInRequested,
    this.onVersionTap,
    this.onCopyVerse,
    this.onShareVerse,
  });

  final YouVersionContentClient content;
  final Bible bible;
  final BibleVersionIndex index;
  final String initialChapterId;
  final YouVersionReaderStorage storage;

  /// Required only to create/replay highlights - the reader still works
  /// read-only without it (verse taps just won't offer highlight colors).
  final YouVersionHighlightsClient? highlightsClient;

  /// Current user's access token, if signed in. When `null`, highlight
  /// requests are queued via [PendingHighlightQueue] instead of sent
  /// immediately, and [onSignInRequested] is offered from the verse-action
  /// sheet. Also gates fetching this chapter's existing highlights (an
  /// anonymous reader has none to fetch).
  final String? userAccessToken;
  final VoidCallback? onSignInRequested;

  /// Shows a "change version" button in the app bar when set - `BibleReader`
  /// has no version/language-switching UI of its own (picking *which*
  /// versions to offer, e.g. via `BibleVersionPicker`/`BibleLanguagePicker`,
  /// is app policy, not SDK policy - same reasoning `_ui`'s pickers already
  /// take data as a caller-supplied list rather than calling
  /// `YouVersionContentClient.listBibles` themselves). `null` hides the
  /// button entirely (previous behavior, unchanged).
  final VoidCallback? onVersionTap;

  /// Called with the tapped verse's plain text (via
  /// `extractVersePlainText`) when "Copy" is tapped in the verse-action
  /// sheet. `null` hides that button - same "null hides it, caller owns
  /// the platform action" pattern as [onVersionTap]. This package stays
  /// free of a clipboard dependency of its own; a typical implementation
  /// is `Clipboard.setData(ClipboardData(text: text))`.
  final ValueChanged<String>? onCopyVerse;

  /// Same as [onCopyVerse], for "Share" - typically `Share.share(text)`
  /// (`share_plus`) or similar. This package has no opinion on which
  /// share mechanism the host app uses.
  final ValueChanged<String>? onShareVerse;

  @override
  State<BibleReader> createState() => _BibleReaderState();
}

class _BibleReaderState extends State<BibleReader> {
  late final BibleReaderController _controller;
  late final ReaderSettingsStorage _settingsStorage;
  late final PendingHighlightQueue _pendingQueue;

  // `null` when no `highlightsClient` was provided (read-only reader).
  // Handles the signed-in write path (create/re-color/remove) with
  // retry+backoff - see its doc comment. `PendingHighlightQueue` above
  // still separately covers the signed-out, survives-a-restart case;
  // the two aren't redundant. Constructed once here, same as
  // `_controller`/`_pendingQueue` - not reactive to `widget.highlightsClient`
  // changing later, matching this widget's existing conventions.
  late final YouVersionHighlightsSyncEngine? _highlightsSyncEngine;
  BiblePassage? _passage;
  Object? _loadError;
  Duration? _retryAfterRemaining;

  /// Chapter id `_loadChapter` last started loading for - guards
  /// `_onControllerChanged` from re-triggering `_loadChapter` on every
  /// controller change (selection, highlights, font settings...), not just
  /// an actual chapter change. Without this, `_loadChapter`'s own
  /// `setLoading(true)` call would re-enter `_onControllerChanged`
  /// synchronously (`ChangeNotifier.notifyListeners` is synchronous) and
  /// call `_loadChapter` again before the first call's first `await`.
  String? _loadedChapterId;

  @override
  void initState() {
    super.initState();
    _controller = BibleReaderController(
      content: widget.content,
      bible: widget.bible,
      index: widget.index,
      initialChapterId: widget.initialChapterId,
    );
    _settingsStorage = ReaderSettingsStorage(widget.storage);
    _pendingQueue = PendingHighlightQueue(widget.storage);
    final client = widget.highlightsClient;
    _highlightsSyncEngine = client == null
        ? null
        : YouVersionHighlightsSyncEngine(client: client, accessToken: () => widget.userAccessToken);
    _controller.addListener(_onControllerChanged);
    _loadSettings();
    _loadChapter();
  }

  @override
  void didUpdateWidget(covariant BibleReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final token = widget.userAccessToken;
    if (token != null && oldWidget.userAccessToken == null && widget.highlightsClient != null) {
      _pendingQueue.replay(client: widget.highlightsClient!, userAccessToken: token);
    }
    // A sign-out (or the token going missing) drops any in-flight/backed-
    // off retry from the old session instead of letting it resend under
    // whatever session (or lack of one) comes next - see
    // `YouVersionHighlightsSyncEngine.reset`'s doc comment.
    if (token == null && oldWidget.userAccessToken != null) {
      _highlightsSyncEngine?.reset();
    }
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsStorage.load();
    _controller.updateFontSettings(settings);
  }

  Future<void> _loadChapter() async {
    // `_controller.chapterId` is always already a full USFM passage id
    // (e.g. "JHN.3") - it only ever comes from `initialChapterId`,
    // `ChapterNavigation`, or `ReferencesScreen`, all of which resolve to
    // `BibleChapter.passageId`/`BibleBookIntro.passageId`, never the bare
    // local `.id` field - so it's directly usable as `getPassage`'s
    // `passageId` with no extra lookup needed.
    final chapterId = _controller.chapterId;
    _loadedChapterId = chapterId;
    _controller.setLoading(true);
    if (_loadError != null) setState(() => _loadError = null);
    final token = widget.userAccessToken;
    final client = widget.highlightsClient;

    try {
      // Both requests are already in flight before either `await` below
      // runs them concurrently, not sequentially.
      final passageFuture = _controller.content.getPassage(bibleId: _controller.bible.id, passageId: chapterId);
      final highlightsFuture = (token != null && client != null)
          ? client.listHighlights(userAccessToken: token, bibleId: _controller.bible.id, passageId: chapterId)
          : Future.value(const <Highlight>[]);

      final passage = await passageFuture;
      final highlights = await highlightsFuture;
      if (!mounted) return;
      setState(() => _passage = passage);
      _controller.setVerseHighlights(highlights);
    } catch (error) {
      // Without this, any exception here (a network failure, a response
      // shape this package didn't expect - confirmed live, a `Highlight`
      // missing `id` used to throw an uncaught type-cast error right in
      // this method) left `isLoading` stuck `true` forever - an
      // "infinite loading" bug report that was actually an unhandled
      // exception the whole time, not a hang. See `docs/DECISIONS.md`.
      if (mounted) {
        setState(() {
          _loadError = error;
          _retryAfterRemaining = error is YouVersionException ? error.retryAfter : null;
        });
        _tickRetryAfter();
      }
    } finally {
      _controller.setLoading(false);
    }
  }

  /// Counts `_retryAfterRemaining` down to zero (confirmed live: a `429`
  /// here sends `Retry-After: 600`, 10 minutes - retrying immediately just
  /// gets rate-limited again, so the retry button disables until it
  /// elapses instead of inviting another useless tap).
  void _tickRetryAfter() {
    final remaining = _retryAfterRemaining;
    if (remaining == null || remaining <= Duration.zero) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _retryAfterRemaining = remaining - const Duration(seconds: 1));
      _tickRetryAfter();
    });
  }

  String _loadErrorMessage(BuildContext context, Object error) {
    if (error is! YouVersionException) return '$error';
    final strings = youVersionReaderStringsOf(context);
    return switch (error.reason) {
      YouVersionErrorReason.rateLimited => strings.rateLimitedError,
      YouVersionErrorReason.missingAuthentication => strings.signInRequiredError,
      YouVersionErrorReason.notPermitted => strings.notPermittedError,
      YouVersionErrorReason.invalidResponse => strings.invalidResponseError,
      YouVersionErrorReason.cannotDownload || YouVersionErrorReason.unknown => strings.loadFailedError,
    };
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    if (_controller.chapterId != _loadedChapterId) _loadChapter();
  }

  Future<void> _openReferences() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ReferencesScreen(
          index: _controller.index,
          onChapterSelected: (chapterId) => Navigator.of(context).pop(chapterId),
        ),
      ),
    );
    if (selected != null) await _controller.goToChapter(selected);
  }

  Future<void> _openFontSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => FontSettingsSheet(
        settings: _controller.fontSettings,
        onChanged: (settings) {
          _controller.updateFontSettings(settings);
          _settingsStorage.save(settings);
        },
      ),
    );
  }

  Future<void> _openFootnote(String footnoteText) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(footnoteText),
        ),
      ),
    );
  }

  void _onVerseTapped(String verseId) {
    final wasSelected = _controller.selectedVerseId == verseId;
    _controller.selectVerse(verseId);
    if (!wasSelected) _openVerseActions(verseId);
  }

  Future<void> _openVerseActions(String verseId) async {
    // Highlighting needs a `highlightsClient` (or at least somewhere to
    // queue the request), but copy/share don't - only skip the whole
    // sheet when NONE of the three would show anything.
    if (widget.highlightsClient == null && widget.onCopyVerse == null && widget.onShareVerse == null) {
      _controller.clearSelection();
      return;
    }
    // Confirmed live: local number is the part after the chapter id's own
    // dot-separated prefix (`"JHN.3.16"` under chapter `"JHN.3"` -> `"16"`).
    final verseNumber =
        verseId.startsWith('${_controller.chapterId}.') ? verseId.substring(_controller.chapterId.length + 1) : verseId;
    final verseText = _passage == null ? null : extractVersePlainText(_passage!.content, verseNumber);

    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => VerseActionSheet(
        selectedColor: _controller.verseHighlights[verseId],
        onColorSelected: widget.highlightsClient == null ? null : (hex) => _applyHighlight(verseId, hex),
        onRemoveHighlight: _controller.verseHighlights[verseId] == null ? null : () => _removeHighlight(verseId),
        onCopy: (verseText == null || widget.onCopyVerse == null) ? null : () => widget.onCopyVerse!(verseText),
        onShare: (verseText == null || widget.onShareVerse == null) ? null : () => widget.onShareVerse!(verseText),
      ),
    );
    if (mounted) _controller.clearSelection();
  }

  Future<void> _applyHighlight(String verseId, String hex) async {
    // Optimistic: mark the verse immediately regardless of sign-in state -
    // without this, a signed-out tap (queued below, not sent yet) left the
    // verse looking un-highlighted with no feedback the tap did anything.
    _controller.putVerseHighlight(verseId, hex);
    final token = widget.userAccessToken;
    if (token == null) {
      await _pendingQueue.enqueue(
        PendingHighlightRequest(bibleId: _controller.bible.id, passageId: verseId, color: hex),
      );
      widget.onSignInRequested?.call();
      return;
    }
    // Routed through the sync engine, not a direct `client.createHighlight`
    // call - a failure here (network blip, transient server error) now
    // gets retried with backoff instead of being silently lost. Fire-and-
    // forget, same as the engine's own API - `_controller`'s optimistic
    // color above is the UI's source of truth either way, so there's
    // nothing further to await here.
    _highlightsSyncEngine?.setHighlight(
      bibleId: _controller.bible.id,
      chapterId: _controller.chapterId,
      passageId: verseId,
      color: hex,
    );
  }

  void _removeHighlight(String verseId) {
    // Optimistic, same reasoning as _applyHighlight - unmark immediately
    // regardless of sign-in state.
    _controller.removeVerseHighlight(verseId);
    final token = widget.userAccessToken;
    // No offline queue for removal (unlike creation via PendingHighlightQueue)
    // - a signed-out removal only clears the local optimistic mark, nothing
    // to actually delete server-side yet since nothing was ever sent.
    if (token == null) return;
    _highlightsSyncEngine?.removeHighlight(
      bibleId: _controller.bible.id,
      chapterId: _controller.chapterId,
      passageId: verseId,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _highlightsSyncEngine?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Extracted to `ReadingThemeScope` - see its doc comment for why this
    // is a fresh `ThemeData`, not a `copyWith`.
    return ReadingThemeScope(
      fontSettings: _controller.fontSettings,
      child: Builder(builder: _buildScaffold),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final readerColors = ReaderColorScheme.of(context);
    final strings = youVersionReaderStringsOf(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final passage = _passage;

    return Scaffold(
      backgroundColor: readerColors.readingCanvas,
      appBar: AppBar(
        title: TextButton(
          onPressed: _openReferences,
          child: Text(_controller.bible.title ?? strings.bibleFallbackTitle, overflow: TextOverflow.ellipsis),
        ),
        actions: [
          if (widget.onVersionTap != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: strings.changeVersionTooltip,
              onPressed: widget.onVersionTap,
            ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: strings.fontSettingsTooltip,
            onPressed: _openFontSettings,
          ),
          YouVersionSignInButton(
            mode: YouVersionSignInButtonMode.iconOnly,
            onPressed: widget.userAccessToken == null ? widget.onSignInRequested : null,
          ),
        ],
      ),
      body: _loadError != null
          ? Builder(
              builder: (context) {
                final remaining = _retryAfterRemaining;
                final waiting = remaining != null && remaining > Duration.zero;
                final errorTextTheme = BibleTextTheme.of(context);
                // SingleChildScrollView, not just Center: this body has no
                // guaranteed minimum height from callers embedding
                // BibleReader in a constrained area - confirmed live,
                // fixed-height content (icon+text+button) forced into a
                // too-small box overflows ("RenderFlex overflowed") instead
                // of just scrolling.
                return SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Explicit style, not the ambient default - this
                          // Builder sits inside the reader's own themed
                          // subtree, but confirmed live, relying on
                          // inherited `DefaultTextStyle` alone rendered
                          // unstyled (wrong color/size against the chosen
                          // reader theme). `BibleTextTheme.scriptureM`
                          // matches what the rest of this reader's text
                          // actually uses.
                          Text(
                            _loadErrorMessage(context, _loadError!),
                            textAlign: TextAlign.center,
                            style: errorTextTheme.scriptureM,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: waiting ? null : _loadChapter,
                            child: Text(waiting
                                ? '${strings.tryAgainButton} (${remaining.inSeconds}s)'
                                : strings.tryAgainButton),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : _controller.isLoading || passage == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: BibleTextView(
                    content: passage.content,
                    chapterId: _controller.chapterId,
                    // `copyright`, not `readerFooter` (`info`) - confirmed
                    // live against 3 real bibles (206/WEBUS, 1/KJV,
                    // 111/NIV), `info` is `null` for every one of them,
                    // `copyright` is the field that's actually populated
                    // (public-domain bibles like WEBUS/KJV still return
                    // `null` there too - nothing to show, correctly no
                    // footer). Falls back to `readerFooter` in case some
                    // other bible ever populates only that one instead.
                    footer: _controller.bible.copyright ?? _controller.bible.readerFooter,
                    selectedVerseIds: {if (_controller.selectedVerseId != null) _controller.selectedVerseId!},
                    highlightsByVerseId: _controller.verseHighlights,
                    isRightToLeft: _controller.bible.isRightToLeft,
                    bionicReading: _controller.fontSettings.bionicReading,
                    onVerseTap: _onVerseTapped,
                    onFootnoteTap: _openFootnote,
                  ),
                ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              // "Previous" points visually right in RTL locales (matches
              // AppBar's own back-button mirroring), not just the reading
              // direction of the passage itself.
              icon: Icon(isRtl ? Icons.chevron_right : Icons.chevron_left),
              tooltip: strings.previousChapterTooltip,
              onPressed: _controller.hasPreviousChapter ? _controller.goToPreviousChapter : null,
            ),
            Text(_controller.chapterId),
            IconButton(
              icon: Icon(isRtl ? Icons.chevron_left : Icons.chevron_right),
              tooltip: strings.nextChapterTooltip,
              onPressed: _controller.hasNextChapter ? _controller.goToNextChapter : null,
            ),
          ],
        ),
      ),
    );
  }
}
