import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

import 'country_dropdown.dart';
import 'error_retry.dart';
import 'l10n/example_localizations.dart';

const _lastPositionStorageKey = 'bible_explorer_last_position';

/// Which of the book/chapter/verse picker sections is currently expanded
/// below the segmented header row - `null` means all 3 are collapsed.
/// Picking an item in the expanded section auto-advances to the next one
/// (book → chapter → verse → all collapsed), so only one section's chip
/// list is ever on screen at a time instead of three stacked `Wrap`s -
/// requested explicitly for the drill-down UX once a book/chapter/verse
/// has actually been picked (nothing left to scroll past to reach the
/// passage text below).
enum _ExplorerSection { book, chapter, verse }

/// Drills into the Content API's full book → chapter → verse tree,
/// exercising every `YouVersionContentClient` method not already covered by
/// `BibleReader`/the reader page: `listBibles`, `getBible`, `getIndex`,
/// `listBooks`, `getBook`, `listChapters`, `getChapter`, `listVerses`,
/// `getVerse`, `getPassage`. Also demonstrates `BibleLanguagePicker`/
/// `BibleVersionPicker`.
///
/// **Same interaction model as `BibleReader`, reusing its actual public
/// pieces instead of re-implementing them** - `_reader` exports
/// `BibleReaderController`/`PendingHighlightQueue`/`ReaderSettingsStorage`/
/// `ReadingThemeScope`/`FontSettingsSheet` precisely so a host app can
/// build its own reading surface without either forking `BibleReader`'s
/// internals or pushing a whole new screen (this page stays inline, per
/// explicit ask - not "open the verse in the Reader"): picking a verse
/// shows the whole chapter (not an isolated snippet) via `BibleTextView`,
/// scrolled to and briefly flash-highlighted; tapping a verse offers real
/// persisted highlight colors (`YouVersionHighlightsClient`, offline-queued
/// via the same `PendingHighlightQueue` `BibleReader` uses when signed
/// out) plus copy/share; the reading theme/font (`ReaderFontSettings`) is
/// loaded from the same storage key `BibleReader` saves to, so a theme
/// picked in the Reader shows here too, and vice versa; and the last
/// language/book/chapter/verse position is saved locally, restored on
/// next open instead of always starting from the country/language picker.
class BibleExplorerPage extends StatefulWidget {
  const BibleExplorerPage({
    super.key,
    required this.content,
    required this.languages,
    required this.highlights,
    required this.storage,
    this.userAccessToken,
    this.onSignInRequested,
  });

  final YouVersionContentClient content;
  final YouVersionLanguagesClient languages;
  final YouVersionHighlightsClient highlights;
  final YouVersionReaderStorage storage;
  final String? userAccessToken;
  final VoidCallback? onSignInRequested;

  @override
  State<BibleExplorerPage> createState() => _BibleExplorerPageState();
}

class _BibleExplorerPageState extends State<BibleExplorerPage> {
  Bible? _bible;
  BibleBook? _book;
  List<BibleChapter>? _chapters;
  BibleChapter? _chapter;
  BibleVerse? _verse;
  BiblePassage? _chapterPassage;
  Object? _chapterPassageError;
  Set<String> _selectedVerseIds = {};
  String? _flashVerseId;
  Map<String, String> _verseHighlights = const {};
  final String _displayLocale = 'en';
  _ExplorerSection? _expandedSection = _ExplorerSection.book;
  // Controls the passage's own `ListView` (not `BibleTextView` itself,
  // which is a plain non-scrolling `Column`) - prev/next chapter buttons
  // jump this to the bottom/top respectively once the new chapter has
  // loaded, per explicit ask: "next" should land reading at the top of
  // the new chapter, "previous" at its end (as if scrolling backwards
  // into it), rather than keeping whatever scroll offset the old chapter
  // was left at.
  final _passageScrollController = ScrollController();

  late final ReaderSettingsStorage _settingsStorage;
  late final PendingHighlightQueue _pendingQueue;
  ReaderFontSettings _fontSettings = const ReaderFontSettings();
  bool _isRestoring = true;

  @override
  void initState() {
    super.initState();
    _settingsStorage = ReaderSettingsStorage(widget.storage);
    _pendingQueue = PendingHighlightQueue(widget.storage);
    _init();
  }

  @override
  void dispose() {
    _passageScrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _fontSettings = await _settingsStorage.load();
    if (mounted) setState(() {});
    await _restorePosition();
  }

  Future<void> _savePosition() async {
    final bible = _bible;
    final book = _book;
    final chapter = _chapter;
    if (bible == null || book == null || chapter == null) return;
    await widget.storage.setString(
      _lastPositionStorageKey,
      jsonEncode({
        'bible_id': bible.id,
        'book_id': book.id,
        'chapter_id': chapter.id,
        // Not `_selectedVerseIds` alone - confirmed live, that field is
        // only populated by tapping verses *inside* the rendered passage
        // (`_onVerseTapped`), not by picking one from the verse-chip list
        // (`_openVerse`, which only sets `_flashVerseId`) - saving just
        // `_selectedVerseIds` silently dropped the verse picked via chip.
        'verse_id': _selectedVerseIds.isNotEmpty ? _selectedVerseIds.first : _flashVerseId,
      }),
    );
  }

  // Returns to the language/book/chapter/verse position last left off at,
  // instead of always starting from the country/language picker - the
  // position is saved (`_savePosition`) every time a chapter/verse opens.
  Future<void> _restorePosition() async {
    final raw = await widget.storage.getString(_lastPositionStorageKey);
    if (raw == null) {
      setState(() => _isRestoring = false);
      await _pickLanguage();
      return;
    }
    try {
      final saved = jsonDecode(raw) as Map<String, dynamic>;
      final bible = await widget.content.getBible(saved['bible_id'] as int);
      final book = await widget.content.getBook(bibleId: bible.id, bookUsfm: saved['book_id'] as String);
      final chapters = await widget.content.listChapters(bibleId: bible.id, bookUsfm: book.id);
      final chapter = await widget.content.getChapter(
        bibleId: bible.id,
        bookUsfm: book.id,
        chapterId: saved['chapter_id'] as String,
      );
      if (!mounted) return;
      setState(() {
        _bible = bible;
        _book = book;
        _chapters = chapters;
        _chapter = chapter;
        _isRestoring = false;
        // Everything already picked - start fully collapsed, straight to
        // the passage text, not the book picker.
        _expandedSection = null;
      });
      // Unconditional, not just `if (verseId != null)` - confirmed live,
      // a saved position with no verse (chapter opened but no verse
      // picked yet) never loaded the chapter passage at all on restore.
      // `_openChapterPassage(null)` is a normal, valid call (`_openChapter`
      // makes it too).
      await _openChapterPassage(saved['verse_id'] as String?);
    } catch (error) {
      // A stale saved position (deleted bible/book/chapter server-side)
      // shouldn't strand the page - fall back to the normal picker flow.
      setState(() => _isRestoring = false);
      await _pickLanguage();
    }
  }

  // Confirmed live: `listLanguages` has `total_size` 8583 - "load every
  // page up front" means ~87 sequential requests, which either looks like
  // infinite loading or trips the API's burst rate limit.
  // `BibleLanguagePicker` takes a flat pre-fetched list with no
  // incremental-loading support of its own (see `LanguagesPage` for a
  // proper "Load more" implementation of that instead). `country` is the
  // only server-side filter this endpoint has (confirmed against both
  // `platform-sdk-kotlin` and `platform-sdk-react` - no free-text search
  // param exists) and cuts the list dramatically (`country=BR`: 8583 →
  // 55), so a real answer here is prompting for a country first, then
  // safely loading every page of that much smaller filtered result -
  // falling back to just the unfiltered first page when the user skips
  // the filter.
  Future<List<Language>> _loadLanguages(String? country) async {
    if (country == null) {
      final page = await widget.languages.listLanguages(pageSize: 99);
      return page.data;
    }
    final all = <Language>[];
    String? pageToken;
    do {
      final page = await widget.languages.listLanguages(country: country, pageSize: 99, pageToken: pageToken);
      all.addAll(page.data);
      pageToken = page.nextPageToken;
    } while (pageToken != null);
    return all;
  }

  // Dismissing the dialog (tap outside/back) and explicitly picking "All
  // countries" both mean the same thing here - proceed with no filter -
  // so there's no separate "cancelled" outcome to track.
  Future<String?> _promptCountryFilter() async {
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ExampleLocalizations.of(context).filterByCountryTitle),
        content: CountryDropdown(autofocus: true, onSelected: (country) => Navigator.pop(context, country)),
      ),
    );
  }

  Future<List<Bible>> _loadAllBibles(String languageId) async {
    final all = <Bible>[];
    String? pageToken;
    do {
      final page = await widget.content.listBibles(
        languageRanges: [languageId],
        pageSize: 99,
        pageToken: pageToken,
      );
      all.addAll(page.data);
      pageToken = page.nextPageToken;
    } while (pageToken != null);
    return all;
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
  }

  Future<void> _pickLanguage() async {
    final country = await _promptCountryFilter();
    if (!mounted) return;

    final List<Language> languages;
    try {
      languages = await _loadLanguages(country);
    } catch (error) {
      _showError(error);
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => BibleLanguagePicker(
        languages: languages,
        displayLocale: _displayLocale,
        onSelected: (language) {
          Navigator.pop(context);
          _pickVersion(language.id);
        },
      ),
    );
  }

  Future<void> _pickVersion(String languageId) async {
    final List<Bible> bibles;
    try {
      bibles = await _loadAllBibles(languageId);
    } catch (error) {
      _showError(error);
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => BibleVersionPicker(
        bibles: bibles,
        onSelected: (bible) async {
          Navigator.pop(context);
          try {
            // getBible on top of the summary listBibles already returned -
            // exercises the single-item endpoint too, and picks up fields
            // listBibles' sparse fieldset may omit.
            final full = await widget.content.getBible(bible.id);
            if (!mounted) return;
            setState(() {
              _bible = full;
              _book = null;
              _chapter = null;
              _verse = null;
              _chapterPassage = null;
              _chapterPassageError = null;
              _selectedVerseIds = {};
              _flashVerseId = null;
              _verseHighlights = const {};
              _expandedSection = _ExplorerSection.book;
            });
          } catch (error) {
            _showError(error);
          }
        },
      ),
    );
  }

  Future<void> _openBook(BibleBook summary) async {
    try {
      final book = await widget.content.getBook(bibleId: _bible!.id, bookUsfm: summary.id);
      // Fetched once here (not just by the chapter chip list's own
      // `FutureBuilder`) so the prev/next chapter buttons around the
      // passage below always have the book's full chapter order to hand,
      // regardless of whether the chapter section has ever been expanded.
      final chapters = await widget.content.listChapters(bibleId: _bible!.id, bookUsfm: book.id);
      if (!mounted) return;
      setState(() {
        _book = book;
        _chapters = chapters;
        _chapter = null;
        _verse = null;
        _chapterPassage = null;
        _chapterPassageError = null;
        _selectedVerseIds = {};
        _flashVerseId = null;
        _verseHighlights = const {};
        _expandedSection = _ExplorerSection.chapter;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _openChapter(BibleChapter summary) async {
    try {
      final chapter = await widget.content.getChapter(bibleId: _bible!.id, bookUsfm: _book!.id, chapterId: summary.id);
      if (!mounted) return;
      setState(() {
        _chapter = chapter;
        _verse = null;
        _expandedSection = _ExplorerSection.verse;
      });
      await _openChapterPassage(null);
    } catch (error) {
      _showError(error);
    }
  }

  // Previous/next chapter buttons around the passage - looks up the
  // current chapter's index in the cached `_chapters` (same list the book's
  // chapter chips use, fetched once in `_openBook`/`_restorePosition`) and
  // opens the neighboring one. `null` at either end of the book (no
  // wraparound into the next/previous book - out of scope here).
  BibleChapter? _chapterAtOffset(int delta) {
    final chapters = _chapters;
    final chapter = _chapter;
    if (chapters == null || chapter == null) return null;
    final index = chapters.indexWhere((c) => c.id == chapter.id);
    final targetIndex = index + delta;
    if (index == -1 || targetIndex < 0 || targetIndex >= chapters.length) return null;
    return chapters[targetIndex];
  }

  // "Next chapter" lands at the top (start reading from its beginning),
  // "previous chapter" at the bottom (its end, as if having scrolled
  // backwards into it) - `_openChapter` itself doesn't touch scroll
  // position, so the jump only happens once the new chapter's passage has
  // actually loaded and been laid out (`addPostFrameCallback`, after the
  // `setState` inside `_openChapterPassage` triggers a rebuild) - jumping
  // any earlier would use the *old* chapter's `maxScrollExtent`.
  Future<void> _goToNextChapter(BibleChapter chapter) async {
    await _openChapter(chapter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_passageScrollController.hasClients) _passageScrollController.jumpTo(0);
    });
  }

  Future<void> _goToPreviousChapter(BibleChapter chapter) async {
    await _openChapter(chapter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_passageScrollController.hasClients) {
        _passageScrollController.jumpTo(_passageScrollController.position.maxScrollExtent);
      }
    });
  }

  // Shows the whole chapter, like `BibleReader` does - not just a single
  // verse - loads its saved highlights (real `YouVersionHighlightsClient`
  // data, not just a UI flash), and if [initialVerseId] is given, scrolls
  // to and briefly flash-highlights it (`BibleTextView.scrollToVerseId`) -
  // same "jump to a verse inside its real context" experience as the
  // Reader instead of an isolated snippet.
  Future<void> _openChapterPassage(String? initialVerseId) async {
    final bible = _bible;
    final chapter = _chapter;
    if (bible == null || chapter == null) return;
    try {
      final chapterPassageId = chapter.passageId ?? chapter.id;
      final passageFuture = widget.content.getPassage(bibleId: bible.id, passageId: chapterPassageId);
      final token = widget.userAccessToken;
      final highlightsFuture = token == null
          ? Future.value(const <Highlight>[])
          : widget.highlights.listHighlights(userAccessToken: token, bibleId: bible.id, passageId: chapterPassageId);
      final passage = await passageFuture;
      final highlights = await highlightsFuture;
      if (!mounted) return;
      setState(() {
        _chapterPassage = passage;
        _chapterPassageError = null;
        _verseHighlights = {for (final h in highlights) h.passageId: h.color};
        _flashVerseId = initialVerseId;
      });
      await _savePosition();
      if (initialVerseId != null) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _flashVerseId = null);
        });
      }
    } catch (error) {
      if (mounted) setState(() => _chapterPassageError = error);
    }
  }

  Future<void> _openVerse(BibleVerse summary) async {
    try {
      final verse = await widget.content.getVerse(
        bibleId: _bible!.id,
        bookUsfm: _book!.id,
        chapterId: _chapter!.id,
        verseId: summary.id,
      );
      if (!mounted) return;
      setState(() {
        _verse = verse;
        _expandedSection = null;
      });
      await _openChapterPassage(verse.passageId ?? verse.id);
    } catch (error) {
      _showError(error);
    }
  }

  // Tap toggles a verse in/out of the selection (just the dashed
  // underline, nothing else happens) - opening the action sheet is
  // long-press's job, not tap's. Matches the official YouVersion app's
  // model (not this SDK's own opinion, `BibleTextView` just draws
  // whatever set it's given - see its doc comment): tap several verses,
  // then long-press one to act on all of them at once.
  void _onVerseTapped(String verseId) {
    setState(() {
      _selectedVerseIds = {..._selectedVerseIds};
      if (!_selectedVerseIds.remove(verseId)) _selectedVerseIds.add(verseId);
    });
  }

  String _verseNumber(String verseId) {
    final chapterPassageId = _chapter!.passageId ?? _chapter!.id;
    return verseId.startsWith('$chapterPassageId.') ? verseId.substring(chapterPassageId.length + 1) : verseId;
  }

  // Long-pressing a verse that isn't already part of the selection starts
  // a new one-verse selection - so long-press alone (no prior taps) still
  // works, not just "long-press to act on an existing multi-select".
  Future<void> _onVerseLongPressed(String verseId) async {
    if (!_selectedVerseIds.contains(verseId)) {
      setState(() => _selectedVerseIds = {verseId});
    }
    await _openVerseActions();
  }

  // "<curly-quoted verse text(s)>"
  //
  // <Book> <Chapter>:<verses> <VERSION>
  // <bible.com deeplink>
  //
  // Matches (for the quote + reference + version part) the official app's
  // own share-text format - confirmed against `platform-sdk-react`'s
  // `buildVerseShareText`/`buildVerseReference` (`packages/ui/src/lib/
  // verse-share.ts`, itself citing ADR-006/YPE-642): curly quotes, verse
  // texts joined with a space inside a contiguous run and `" ... "`
  // between separate runs, verse *numbers* collapsed to ranges
  // (`"1-3"`) within a run and comma-separated between runs (`"1,3"`).
  // The bible.com URL is this demo's own addition on top of that
  // (explicitly requested) - `platform-sdk-kotlin`'s
  // `BibleVersion.shareUrl` is the confirmed URL shape
  // (`bible.com/bible/{id}/{BOOK}.{chapter}.{verseRange}.{abbreviation}`,
  // falling back to the numeric bible id when there's no abbreviation),
  // but neither reference SDK actually concatenates a URL into the share
  // text itself - no confirmed precedent for that combination, so this is
  // this demo's own judgment call on layout, not a ported format. No full
  // copyright line - see the comment right above where it would go.
  String _buildShareText(List<String> verseIds) {
    final content = _chapterPassage?.content;
    if (content == null || verseIds.isEmpty) return '';

    final numbers = verseIds.map(_verseNumber).toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

    // Group consecutive integer verse numbers into runs, e.g. [1,2,3,5] ->
    // [[1,2,3],[5]] - each run becomes one collapsed range in the
    // reference ("1-3") and one space-joined text block; runs are joined
    // with ", "/" ... " respectively.
    final runs = <List<String>>[];
    for (final number in numbers) {
      final asInt = int.tryParse(number);
      final lastRun = runs.isEmpty ? null : runs.last;
      final lastInt = lastRun == null ? null : int.tryParse(lastRun.last);
      if (lastRun != null && asInt != null && lastInt != null && asInt == lastInt + 1) {
        lastRun.add(number);
      } else {
        runs.add([number]);
      }
    }

    final numberRanges = runs.map((run) => run.length == 1 ? run.single : '${run.first}-${run.last}').join(',');
    // Verse numbers inline with the text (like normal scripture layout,
    // "16 For God so loved... 17 For God did not...") only when more than
    // one verse is selected - for a single verse the reference line alone
    // already says exactly which one it is, no number needed inline
    // (matches the confirmed React format's own single-verse example,
    // which has none - this demo only adds them for the multi-verse case
    // React's own example doesn't actually number either, an explicit
    // ask beyond the ported format).
    final showInlineNumbers = numbers.length > 1;
    final textRuns = runs
        .map((run) => run
            .map((n) {
              final text = extractVersePlainText(content, n);
              if (text == null) return null;
              return showInlineNumbers ? '$n $text' : text;
            })
            .whereType<String>()
            .join(' '))
        .where((text) => text.isNotEmpty)
        .toList();
    if (textRuns.isEmpty) return '';
    final quotedText = '“${textRuns.join(' ... ')}”';

    final bible = _bible!;
    final versionLabel = bible.abbreviation ?? bible.title ?? '';
    final bookName = _book!.title ?? _book!.id;
    final chapterNumber = _chapter!.id;
    final reference = '$bookName $chapterNumber:$numberRanges${versionLabel.isEmpty ? '' : ' $versionLabel'}';

    final urlAbbreviation = (bible.abbreviation?.isNotEmpty ?? false) ? bible.abbreviation! : '${bible.id}';
    final urlVerseSegment = runs.length == 1
        ? (runs.single.length == 1 ? runs.single.single : '${runs.single.first}-${runs.single.last}')
        : '${numbers.first}-${numbers.last}';
    final deepLink = 'https://www.bible.com/bible/${bible.id}/${_book!.id}.$chapterNumber.$urlVerseSegment.'
        '$urlAbbreviation';

    // No full copyright line - confirmed live, a real one is a multi-line
    // legal paragraph (NIV: 168 chars, NASB: 210+), not a short credit;
    // neither reference SDK's share format includes one either (the
    // version abbreviation already in `reference` is the attribution).
    final lines = [quotedText, '', reference, deepLink];
    return lines.join('\n');
  }

  Future<void> _openVerseActions() async {
    final verseIds = _selectedVerseIds.toList()
      ..sort((a, b) => (int.tryParse(_verseNumber(a)) ?? 0).compareTo(int.tryParse(_verseNumber(b)) ?? 0));
    final combinedText = _buildShareText(verseIds);
    final strings = ExampleLocalizations.of(context);

    // A single shared color only if every selected verse already has the
    // *same* one - otherwise there's no one color to show as "selected"
    // in the sheet.
    final colors = verseIds.map((id) => _verseHighlights[id]).toSet();
    final sharedColor = colors.length == 1 ? colors.single : null;
    final anyHighlighted = verseIds.any((id) => _verseHighlights.containsKey(id));

    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => VerseActionSheet(
        selectedColor: sharedColor,
        onColorSelected: (hex) => _applyHighlight(verseIds, hex),
        onRemoveHighlight: anyHighlighted ? () => _removeHighlight(verseIds) : null,
        onCopy: combinedText.isEmpty
            ? null
            : () {
                Clipboard.setData(ClipboardData(text: combinedText));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.copiedToClipboardMessage)));
              },
        onShare: combinedText.isEmpty ? null : () => Share.share(combinedText),
      ),
    );
    if (mounted) setState(() => _selectedVerseIds = {});
  }

  Future<void> _applyHighlight(List<String> verseIds, String hex) async {
    // Optimistic, same reasoning as `BibleReader._applyHighlight`.
    setState(() => _verseHighlights = {..._verseHighlights, for (final id in verseIds) id: hex});
    final token = widget.userAccessToken;
    for (final verseId in verseIds) {
      if (token == null) {
        await _pendingQueue.enqueue(PendingHighlightRequest(bibleId: _bible!.id, passageId: verseId, color: hex));
        continue;
      }
      try {
        final highlight = await widget.highlights.createHighlight(
          userAccessToken: token,
          bibleId: _bible!.id,
          passageId: verseId,
          color: hex,
        );
        if (mounted) setState(() => _verseHighlights = {..._verseHighlights, verseId: highlight.color});
      } catch (error) {
        _showError(error);
      }
    }
    if (token == null) widget.onSignInRequested?.call();
  }

  Future<void> _removeHighlight(List<String> verseIds) async {
    setState(() => _verseHighlights = {..._verseHighlights}..removeWhere((id, _) => verseIds.contains(id)));
    final token = widget.userAccessToken;
    if (token == null) return;
    for (final verseId in verseIds) {
      try {
        await widget.highlights.deleteHighlight(userAccessToken: token, bibleId: _bible!.id, passageId: verseId);
      } catch (error) {
        _showError(error);
      }
    }
  }

  Future<void> _openFontSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => FontSettingsSheet(
        settings: _fontSettings,
        onChanged: (settings) {
          setState(() => _fontSettings = settings);
          _settingsStorage.save(settings);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bible = _bible;
    if (_isRestoring || bible == null) return const Center(child: CircularProgressIndicator());
    final strings = ExampleLocalizations.of(context);

    return Column(
      children: [
        // Version + Book/Chapter/Verse header stays pinned above the
        // scrollable passage below, not inside the same `ListView` -
        // requested explicitly, always visible instead of scrolling out of
        // view with the passage text. The version name itself is now the
        // "change" control (tapping it opens the language/version picker,
        // `_pickLanguage`) - the separate "Trocar idioma/versão" button
        // was removed as redundant with it.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
                      onPressed: _pickLanguage,
                      child: Text(bible.title ?? bible.abbreviation ?? '${bible.id}'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_fields),
                    tooltip: strings.fontSettingsTooltip,
                    onPressed: _openFontSettings,
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Segmented Book | Chapter | Verse header - only the tapped
              // section's chip list shows below (not all 3 stacked at
              // once), and picking an item auto-advances to the next
              // section (collapsing everything once a verse is picked) -
              // requested explicitly, "melhor para UX" than always showing
              // every level's full chip list at once.
              Row(
                children: [
                  Expanded(
                    child: _SectionButton(
                      label: _book?.title ?? _book?.id ?? strings.bookSectionLabel,
                      expanded: _expandedSection == _ExplorerSection.book,
                      onPressed: () => setState(
                        () =>
                            _expandedSection = _expandedSection == _ExplorerSection.book ? null : _ExplorerSection.book,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _SectionButton(
                      label: _chapter?.title ?? _chapter?.id ?? strings.chapterSectionLabel,
                      expanded: _expandedSection == _ExplorerSection.chapter,
                      onPressed: _book == null
                          ? null
                          : () => setState(
                                () => _expandedSection =
                                    _expandedSection == _ExplorerSection.chapter ? null : _ExplorerSection.chapter,
                              ),
                    ),
                  ),
                  Expanded(
                    child: _SectionButton(
                      label: _verse?.title ?? _verse?.id ?? strings.verseSectionLabel,
                      expanded: _expandedSection == _ExplorerSection.verse,
                      onPressed: _chapter == null
                          ? null
                          : () => setState(
                                () => _expandedSection =
                                    _expandedSection == _ExplorerSection.verse ? null : _ExplorerSection.verse,
                              ),
                    ),
                  ),
                ],
              ),
              if (_expandedSection == _ExplorerSection.book) ...[
                const SizedBox(height: 8),
                FutureBuilder<List<BibleBook>>(
                  future: widget.content.listBooks(bible.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return ErrorRetry(error: snapshot.error!, onRetry: () => setState(() {}));
                    final books = snapshot.data;
                    if (books == null) return const Center(child: CircularProgressIndicator());
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final book in books)
                          ChoiceChip(
                            label: Text(book.title ?? book.id),
                            selected: _book?.id == book.id,
                            onSelected: (_) => _openBook(book),
                          ),
                      ],
                    );
                  },
                ),
              ] else if (_expandedSection == _ExplorerSection.chapter) ...[
                const SizedBox(height: 8),
                if (_chapters == null)
                  const Center(child: CircularProgressIndicator())
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final chapter in _chapters!)
                        ChoiceChip(
                          label: Text(chapter.title ?? chapter.id),
                          selected: _chapter?.id == chapter.id,
                          onSelected: (_) => _openChapter(chapter),
                        ),
                    ],
                  ),
              ] else if (_expandedSection == _ExplorerSection.verse) ...[
                const SizedBox(height: 8),
                FutureBuilder<List<BibleVerse>>(
                  future: widget.content.listVerses(bibleId: bible.id, bookUsfm: _book!.id, chapterId: _chapter!.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return ErrorRetry(error: snapshot.error!, onRetry: () => setState(() {}));
                    final verses = snapshot.data;
                    if (verses == null) return const Center(child: CircularProgressIndicator());
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final verse in verses)
                          ChoiceChip(
                            label: Text(verse.title ?? verse.id),
                            selected: _verse?.id == verse.id,
                            onSelected: (_) => _openVerse(verse),
                          ),
                      ],
                    );
                  },
                ),
              ],
              const Divider(height: 1),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: _passageScrollController,
            padding: const EdgeInsets.all(16),
            children: [
              if (_chapterPassageError != null)
                ErrorRetry(error: _chapterPassageError!, onRetry: () => _openChapterPassage(_flashVerseId))
              else if (_chapterPassage != null) ...[
                // `_openChapterPassage` skips the highlights request
                // entirely while signed out (`widget.userAccessToken ==
                // null`) - that's correct (no token to call the API
                // with), but silently rendering zero highlights read as
                // "highlights are broken" (real bug, found downstream in
                // `bible_with_me`, 2026-09-03) with no way to tell "you
                // have none" apart from "you're signed out".
                if (widget.userAccessToken == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(child: Text(strings.signInToSyncMessage)),
                          ],
                        ),
                      ),
                    ),
                  ),
                _ChapterNavButton(
                  chapter: _chapterAtOffset(-1),
                  label: strings.previousChapterButton,
                  icon: Icons.arrow_upward,
                  onPressed: _goToPreviousChapter,
                ),
                const SizedBox(height: 8),
                Text(_chapterPassage!.reference, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ReadingThemeScope(
                  fontSettings: _fontSettings,
                  child: Builder(
                    builder: (context) {
                      return Container(
                        color: ReaderColorScheme.of(context).readingCanvas,
                        padding: const EdgeInsets.all(12),
                        child: BibleTextView(
                          content: _chapterPassage!.content,
                          chapterId: _chapter!.passageId ?? _chapter!.id,
                          // See `BibleReader`'s own doc comment on this
                          // same choice - `copyright` is the field that's
                          // actually populated live, `readerFooter`
                          // (`info`) never was across every bible checked.
                          footer: bible.copyright ?? bible.readerFooter,
                          selectedVerseIds: {..._selectedVerseIds, if (_flashVerseId != null) _flashVerseId!},
                          highlightsByVerseId: _verseHighlights,
                          scrollToVerseId: _flashVerseId,
                          isRightToLeft: bible.isRightToLeft,
                          onVerseTap: _onVerseTapped,
                          onVerseLongPress: _onVerseLongPressed,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _ChapterNavButton(
                  chapter: _chapterAtOffset(1),
                  label: strings.nextChapterButton,
                  icon: Icons.arrow_downward,
                  onPressed: _goToNextChapter,
                  iconAfterLabel: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Previous/next chapter button around the passage - hidden entirely
/// (`SizedBox.shrink`) at either end of the book, rather than shown
/// disabled, since there's no next book/wraparound to fall back to here.
class _ChapterNavButton extends StatelessWidget {
  const _ChapterNavButton({
    required this.chapter,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconAfterLabel = false,
  });

  final BibleChapter? chapter;
  final String label;
  final IconData icon;
  final ValueChanged<BibleChapter> onPressed;
  final bool iconAfterLabel;

  @override
  Widget build(BuildContext context) {
    final chapter = this.chapter;
    if (chapter == null) return const SizedBox.shrink();
    final iconWidget = Icon(icon, size: 18);
    final labelWidget = Text(label);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => onPressed(chapter),
        icon: iconAfterLabel ? labelWidget : iconWidget,
        label: iconAfterLabel ? iconWidget : labelWidget,
      ),
    );
  }
}

/// One segment of the Book | Chapter | Verse header - shows the current
/// selection (or a placeholder label), pressed/expanded state via an
/// outline + chevron, disabled (no `onPressed`) until its prerequisite
/// section has a selection.
class _SectionButton extends StatelessWidget {
  const _SectionButton({required this.label, required this.expanded, required this.onPressed});

  final String label;
  final bool expanded;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: expanded ? Theme.of(context).colorScheme.primaryContainer : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18),
        ],
      ),
    );
  }
}
