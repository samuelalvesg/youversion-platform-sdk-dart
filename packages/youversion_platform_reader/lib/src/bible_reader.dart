import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

import 'controllers/bible_reader_controller.dart';
import 'highlights/pending_highlight_queue.dart';
import 'screens/font_settings_sheet.dart';
import 'screens/references_screen.dart';
import 'settings/reader_settings_storage.dart';
import 'storage/youversion_reader_storage.dart';

/// Full Bible-reading screen: header (version + font button + sign-in
/// status), scripture body with text selection, bottom chapter navigation,
/// verse-action sheet on selection, and font-settings sheet.
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
  });

  final YouVersionContentClient content;
  final Bible bible;
  final BibleVersionIndex index;
  final String initialChapterId;
  final YouVersionReaderStorage storage;

  /// Required only to create/replay highlights - the reader still works
  /// read-only without it (verse selection just won't offer highlight
  /// colors).
  final YouVersionHighlightsClient? highlightsClient;

  /// Current user's access token, if signed in. When `null`, highlight
  /// requests are queued via [PendingHighlightQueue] instead of sent
  /// immediately, and [onSignInRequested] is offered from the verse-action
  /// sheet.
  final String? userAccessToken;
  final VoidCallback? onSignInRequested;

  @override
  State<BibleReader> createState() => _BibleReaderState();
}

class _BibleReaderState extends State<BibleReader> {
  late final BibleReaderController _controller;
  late final ReaderSettingsStorage _settingsStorage;
  late final PendingHighlightQueue _pendingQueue;
  BiblePassage? _passage;

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
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsStorage.load();
    _controller.updateFontSettings(settings);
  }

  Future<void> _loadChapter() async {
    _controller.setLoading(true);
    final chapterId = _controller.chapterId;
    final passageId = _findPassageId(_controller.index, chapterId) ?? chapterId;
    final passage = await _controller.content.getPassage(
      bibleId: _controller.bible.id,
      passageId: passageId,
    );
    if (!mounted) return;
    setState(() => _passage = passage);
    _controller.setLoading(false);
  }

  String? _findPassageId(BibleVersionIndex index, String chapterId) {
    for (final book in index.books ?? const []) {
      for (final chapter in book.chapters ?? const []) {
        if (chapter.id == chapterId) return chapter.passageId;
      }
    }
    return null;
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    _loadChapter();
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

  Future<void> _openVerseActions() async {
    if (widget.highlightsClient == null) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => VerseActionSheet(
        selectedColor: _controller.selectedHighlight?.color,
        onColorSelected: (hex) => _applyHighlight(hex),
      ),
    );
  }

  Future<void> _applyHighlight(String hex) async {
    final passageId = _controller.chapterId;
    final token = widget.userAccessToken;
    if (token == null) {
      await _pendingQueue.enqueue(
        PendingHighlightRequest(bibleId: _controller.bible.id, passageId: passageId, color: hex),
      );
      widget.onSignInRequested?.call();
      return;
    }
    final client = widget.highlightsClient;
    if (client == null) return;
    final highlight = await client.createHighlight(
      userAccessToken: token,
      bibleId: _controller.bible.id,
      passageId: passageId,
      color: hex,
    );
    _controller.selectHighlight(highlight);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readerColors = ReaderColorScheme.of(context);
    final passage = _passage;

    return Scaffold(
      backgroundColor: readerColors.readingCanvas,
      appBar: AppBar(
        title: TextButton(
          onPressed: _openReferences,
          child: Text(_controller.bible.title ?? 'Bible', overflow: TextOverflow.ellipsis),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Font settings',
            onPressed: _openFontSettings,
          ),
          YouVersionSignInButton(
            mode: YouVersionSignInButtonMode.iconOnly,
            onPressed: widget.userAccessToken == null ? widget.onSignInRequested : null,
          ),
        ],
      ),
      body: _controller.isLoading || passage == null
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onLongPress: _openVerseActions,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: BibleTextView(content: passage.content, footer: _controller.bible.readerFooter),
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _controller.hasPreviousChapter ? _controller.goToPreviousChapter : null,
            ),
            Text(_controller.chapterId),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _controller.hasNextChapter ? _controller.goToNextChapter : null,
            ),
          ],
        ),
      ),
    );
  }
}
