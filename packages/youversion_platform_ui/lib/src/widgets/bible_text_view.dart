import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../rendering/bible_text_node.dart';
import '../rendering/verse_gesture_recognizer.dart';
import '../theme/bible_text_theme.dart';
import '../theme/reader_color_scheme.dart';

/// Renders a [BiblePassage.content] HTML string ("YVDOM") as scripture
/// text: verse numbers, words-of-Christ (red-letter) styling, inline
/// footnote markers, section headings, and tap-to-select-a-verse.
///
/// Not a general HTML engine - parses the specific subset of markup
/// YouVersion's passage HTML actually uses (`.yv-v`/`.yv-vlbl`/`.wj`/
/// `.yv-n`, see `rendering/bible_text_node.dart`), verified against both
/// `platform-sdk-react`'s transformer test fixtures and real
/// `GET /v1/bibles/{id}/passages/{id}?format=html` responses. Apps needing
/// full HTML fidelity (e.g. table-formatted genealogies) can swap in
/// `flutter_html` and skip this widget.
///
/// Selection model is tap-a-whole-verse, not free-text selection (matches
/// this package's own product decision, not any of the 4 official SDKs -
/// React/Kotlin both use a solid underline for the equivalent "selected"
/// state; this widget uses a dashed one, see `docs/DECISIONS.md`). No
/// picker, no navigation, no data fetching - purely renders what it's
/// given. Mirrors `platform-ui`'s `views/BibleTextView.kt` (Kotlin) /
/// `Views/BibleTextView.swift` (Swift) for the rendering rules, but not
/// their per-character hit-testing - `InlineSpan.recognizer` gives every
/// verse's runs a shared tap target natively, no manual offset math needed.
class BibleTextView extends StatefulWidget {
  const BibleTextView({
    super.key,
    required this.content,
    this.chapterId,
    this.footer,
    this.selectedVerseIds = const {},
    this.highlightsByVerseId = const {},
    this.isRightToLeft = false,
    this.bionicReading = false,
    this.bionicBoldFraction = 1 / 3,
    this.onVerseTap,
    this.onVerseLongPress,
    this.onFootnoteTap,
    this.scrollToVerseId,
  });

  /// Raw passage HTML, as returned by `YouVersionContentClient.getPassage`.
  final String content;

  /// The chapter this passage belongs to (e.g. `"JHN.3"`), combined with
  /// each parsed verse's local number to build a full USFM verse id (e.g.
  /// `"JHN.3.16"`) for [selectedVerseIds]/[highlightsByVerseId]/[onVerseTap].
  /// Leave `null` for a display-only passage with no verse identity (e.g.
  /// [BibleCard]/[VerseOfTheDayCard]'s summary content) - verses render
  /// but tapping them is a no-op regardless of [onVerseTap].
  final String? chapterId;

  /// Optional reader-footer text (`Bible.readerFooter`).
  final String? footer;

  /// Full USFM ids (e.g. `"JHN.3.16"`) of every verse currently selected -
  /// each drawn with a dashed underline plus a lighter selection tint.
  /// Multiple entries support a multi-select flow (tap several verses,
  /// then long-press one to act on all of them - the official YouVersion
  /// app's pattern, not this SDK's own opinion) but this widget doesn't
  /// implement that flow itself, it just draws whatever set it's given;
  /// [BibleReader] only ever puts one verse in here at a time.
  final Set<String> selectedVerseIds;

  /// Saved highlight color (hex, from `HighlightColors`) per full USFM
  /// verse id - drawn as that verse's text background.
  final Map<String, String> highlightsByVerseId;

  /// From `Bible.isRightToLeft` - wraps the content in the matching
  /// [Directionality] (this widget's own text layout only; chapter
  /// navigation icon mirroring is handled separately by `BibleReader`).
  final bool isRightToLeft;

  /// Bolds the leading portion of each word's letters (a fixation point
  /// meant to speed up reading/help focus, not in any of the 3 official
  /// SDKs). Splits each text run into per-word bold/regular span pairs
  /// instead of one plain [TextSpan] - verse numbers and footnote markers
  /// are untouched either way, only actual scripture words are affected.
  /// How much of each word is bolded is [bionicBoldFraction], not fixed.
  ///
  /// Deliberately not labelled by any 3rd-party trademarked name
  /// user-facing - see `ReaderFontSettings.bionicReading`'s doc comment
  /// for the full patent/trademark note behind that and
  /// [bionicBoldFraction]'s default.
  final bool bionicReading;

  /// Fraction (`0.0`-`1.0`) of each word's leading characters bolded when
  /// [bionicReading] is on. Default `1/3` - see [bionicReading]'s doc
  /// comment.
  final double bionicBoldFraction;

  /// Called with a verse's full USFM id when it's tapped. `null` disables
  /// tap-to-select (verses render as plain, non-interactive text unless
  /// [onVerseLongPress] is set).
  final ValueChanged<String>? onVerseTap;

  /// Called with a verse's full USFM id when it's long-pressed - separate
  /// from [onVerseTap] so a caller can use tap for select/deselect and
  /// long-press for "act on the current selection" (e.g. open a copy/
  /// share sheet for every id in [selectedVerseIds]), matching how the
  /// official YouVersion app's verse selection works. `null` disables
  /// long-press (same "null hides/disables it" pattern used throughout
  /// this package).
  final ValueChanged<String>? onVerseLongPress;

  /// Called with a footnote's body text when its marker (`*`) is tapped.
  /// `null` leaves the marker present but inert (the current default
  /// behavior - this package draws no footnote UI of its own; `null` is
  /// backwards-compatible with existing callers).
  final ValueChanged<String>? onFootnoteTap;

  /// Full USFM verse id to scroll into view once, right after this
  /// content first renders (e.g. opening a chapter already focused on a
  /// specific verse, matching how [selectedVerseId] would draw it).
  /// Re-fires on change (a new value scrolls again), but does nothing
  /// once `null`. No-op for a verse id not present in [content].
  final String? scrollToVerseId;

  @override
  State<BibleTextView> createState() => _BibleTextViewState();
}

class _BibleTextViewState extends State<BibleTextView> {
  final List<GestureRecognizer> _recognizers = [];
  final Map<String, GlobalKey> _verseKeys = {};

  // Real perf bug found live 2026-09-08 (reported as recurring Android
  // ANRs "app not responding"): `build()` used to call
  // `parseBibleHtml(widget.content)` directly, every single rebuild -
  // including ones that have nothing to do with the passage TEXT
  // changing (e.g. `BibleWithMe`'s TTS "currently speaking verse"
  // highlight, which calls `setState` on its whole page once per
  // segment/verse while reading a chapter aloud). Re-parsing a whole
  // chapter's HTML (DOM parse via `package:html` + walking every node)
  // on every one of those, for every verse spoken, is real, avoidable
  // main-thread work - long/dense chapters (Psalm 119, 176 verses) make
  // it worse. Cached here instead, recomputed only when [widget.content]
  // itself actually changes - everything else that varies per-rebuild
  // (`selectedVerseIds`/`highlightsByVerseId`/`scrollToVerseId`/
  // `bionicReading`/callbacks) only affects how the ALREADY-parsed
  // blocks are turned into spans in `build()`, not the parse itself.
  late List<BibleTextBlock> _blocks = parseBibleHtml(widget.content);

  @override
  void initState() {
    super.initState();
    _scheduleScroll();
  }

  @override
  void didUpdateWidget(covariant BibleTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != oldWidget.content) {
      _blocks = parseBibleHtml(widget.content);
    }
    if (widget.scrollToVerseId != null && widget.scrollToVerseId != oldWidget.scrollToVerseId) {
      _scheduleScroll();
    }
  }

  void _scheduleScroll() {
    final verseId = widget.scrollToVerseId;
    if (verseId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _verseKeys[verseId]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(context, alignment: 0.3, duration: const Duration(milliseconds: 400));
    });
  }

  GlobalKey _keyFor(String verseId) => _verseKeys.putIfAbsent(verseId, GlobalKey.new);

  /// The scrollable target for [scrollToVerseId] needs a stable
  /// [GlobalKey] per verse; blocks with no derivable verse id (no
  /// [chapterId], or a heading-only block) fall back to an ordinary key -
  /// nothing ever scrolls to those anyway.
  Key _verseKeyFor(BibleVerseBlock block) {
    final chapterId = widget.chapterId;
    final verseId = (chapterId == null || block.number.isEmpty) ? null : '$chapterId.${block.number}';
    return verseId == null ? ValueKey(block) : _keyFor(verseId);
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  GestureRecognizer? _recognizerFor(String? verseId) {
    if (verseId == null || (widget.onVerseTap == null && widget.onVerseLongPress == null)) return null;
    final recognizer = verseTapLongPressRecognizer(
      onTap: widget.onVerseTap == null ? null : () => widget.onVerseTap!(verseId),
      onLongPress: widget.onVerseLongPress == null ? null : () => widget.onVerseLongPress!(verseId),
    );
    _recognizers.add(recognizer);
    return recognizer;
  }

  /// Separate from [_recognizerFor] - tapping a footnote marker opens the
  /// footnote, it doesn't also select the verse.
  TapGestureRecognizer? _footnoteRecognizerFor(String footnoteText) {
    if (widget.onFootnoteTap == null) return null;
    final recognizer = TapGestureRecognizer()..onTap = () => widget.onFootnoteTap!(footnoteText);
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final textTheme = BibleTextTheme.of(context);
    final readerColors = ReaderColorScheme.of(context);

    final children = <Widget>[
      for (final block in _blocks)
        if (block is BibleHeadingBlock)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(block.text, style: textTheme.header),
          )
        else if (block is BibleVerseBlock)
          KeyedSubtree(
            key: _verseKeyFor(block),
            child: Text.rich(_buildVerseSpan(block, textTheme, readerColors)),
          ),
      if (widget.footer != null && widget.footer!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(widget.footer!, style: textTheme.caption),
      ],
    ];

    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: children);

    return Directionality(
      textDirection: widget.isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
      child: content,
    );
  }

  InlineSpan _buildVerseSpan(BibleVerseBlock block, BibleTextTheme textTheme, ReaderColorScheme readerColors) {
    final chapterId = widget.chapterId;
    final verseId = (chapterId == null || block.number.isEmpty) ? null : '$chapterId.${block.number}';
    final highlightHex = verseId == null ? null : widget.highlightsByVerseId[verseId];
    final isSelected = verseId != null && widget.selectedVerseIds.contains(verseId);
    final recognizer = _recognizerFor(verseId);

    var baseStyle = textTheme.scriptureM;
    if (highlightHex != null) {
      final color = Color(int.parse('FF$highlightHex', radix: 16));
      baseStyle = baseStyle.copyWith(background: Paint()..color = readerColors.highlightOverlay(color));
    }
    if (isSelected) {
      baseStyle = baseStyle.copyWith(
        background: highlightHex == null ? (Paint()..color = readerColors.highlightBorder) : baseStyle.background,
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.dashed,
        decorationColor: readerColors.highlightBorder,
      );
    }

    final spans = <InlineSpan>[
      if (block.number.isNotEmpty)
        TextSpan(
          text: '${block.number} ',
          style: baseStyle.copyWith(
              fontSize: (baseStyle.fontSize ?? 15) * 0.6, color: baseStyle.color?.withValues(alpha: 0.6)),
          recognizer: recognizer,
        ),
      for (final run in block.runs)
        if (run.lineBreakIndentLevel != null)
          TextSpan(text: '\n${'  ' * run.lineBreakIndentLevel!}', style: baseStyle)
        else if (run.footnoteText != null)
          TextSpan(
            text: '*',
            style: baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 15) * 0.8),
            recognizer: _footnoteRecognizerFor(run.footnoteText!),
          )
        else if (widget.bionicReading)
          ..._bionicSpans(
            run.text,
            run.isWordsOfChrist ? baseStyle.copyWith(color: readerColors.wordsOfChrist) : baseStyle,
            recognizer,
            widget.bionicBoldFraction,
          )
        else
          TextSpan(
            text: run.text,
            style: run.isWordsOfChrist ? baseStyle.copyWith(color: readerColors.wordsOfChrist) : baseStyle,
            recognizer: recognizer,
          ),
    ];

    return TextSpan(children: spans);
  }

  /// Splits [text] into alternating bold-prefix/regular-suffix
  /// [TextSpan]s per word (whitespace runs pass through unstyled-bold, as
  /// their own span, so exact spacing/line-wrapping is untouched). Bold
  /// length is `ceil(word.length * boldFraction)`, clamped to at least 1
  /// for any non-empty word - a fixed, simple heuristic (not the more
  /// elaborate syllable-aware ones some similar reader features use). The
  /// same [recognizer] is reused across every span for a given run - safe,
  /// [GestureRecognizer] isn't tied 1:1 to a single [InlineSpan].
  static List<InlineSpan> _bionicSpans(
    String text,
    TextStyle baseStyle,
    GestureRecognizer? recognizer,
    double boldFraction,
  ) {
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
    // Achado real (2026-09-07, pedido do usuário): a metade não-negrito
    // usava `baseStyle` sem alteração (mesmo peso do resto do texto) -
    // afinada aqui (`w300`) pra aumentar o contraste com o prefixo em
    // negrito, como a maioria das implementações reais de Bionic
    // Reading faz. Só funciona de verdade com a fonte PADRÃO do sistema
    // (que tem uma face "Light" de verdade) - `OpenDyslexic`/
    // `AtkinsonHyperlegible` (`pubspec.yaml` deste app, únicas fontes
    // customizadas hoje) só empacotam Regular(400)/Bold(700), então o
    // Flutter cai de volta pro peso mais próximo disponível (Regular)
    // pra essas duas - degrada bem (não quebra, só não fica mais fino),
    // não corrigido aqui (exigiria adicionar um arquivo de fonte "Light"
    // pra cada uma).
    final thinStyle = baseStyle.copyWith(fontWeight: FontWeight.w300);
    final spans = <InlineSpan>[];
    for (final match in RegExp(r'\s+|\S+').allMatches(text)) {
      final token = match.group(0)!;
      if (token.trim().isEmpty) {
        spans.add(TextSpan(text: token, style: baseStyle, recognizer: recognizer));
        continue;
      }
      final boldLength = (token.length * boldFraction).ceil().clamp(1, token.length);
      spans.add(TextSpan(text: token.substring(0, boldLength), style: boldStyle, recognizer: recognizer));
      if (boldLength < token.length) {
        spans.add(TextSpan(text: token.substring(boldLength), style: thinStyle, recognizer: recognizer));
      }
    }
    return spans;
  }
}
