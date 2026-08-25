import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// One rendered block of a parsed passage: a section heading, or a verse
/// with its runs of text.
sealed class BibleTextBlock {
  const BibleTextBlock();
}

/// A section heading (USFM `\s1`/`\s2`/`\ms`/`\sp`/`\sr`/`\r`, rendered as
/// class names `s1`/`s2`/`ms`/`sp`/`sr`/`r` in YouVersion's passage HTML) -
/// not part of any verse's content.
final class BibleHeadingBlock extends BibleTextBlock {
  const BibleHeadingBlock(this.text);

  final String text;
}

/// One verse's content, as a flat list of runs in document order.
///
/// [number] is the verse's local number (e.g. `"16"`, from the `v`
/// attribute on YouVersion's `.yv-v` marker) - callers combine it with the
/// chapter id to build a full USFM verse reference (e.g. `"JHN.3.16"`).
/// Empty when the block groups text with no preceding verse marker (e.g. a
/// book/chapter intro paragraph).
final class BibleVerseBlock extends BibleTextBlock {
  BibleVerseBlock(this.number, this.runs);

  final String number;
  final List<BibleTextRun> runs;
}

/// One run of text within a verse, with formatting/footnote flags.
///
/// [text] is empty for a footnote-marker run (`footnoteText` non-null,
/// nothing visible to render besides a marker glyph the caller supplies)
/// and for a line-break run (`lineBreakIndentLevel` non-null, marks the
/// start of a new poetry line rather than any visible glyph).
class BibleTextRun {
  const BibleTextRun({
    required this.text,
    this.isWordsOfChrist = false,
    this.footnoteText,
    this.lineBreakIndentLevel,
  });

  final String text;

  /// From YouVersion's `.wj` class ("words of Jesus"/red-letter).
  final bool isWordsOfChrist;

  /// Footnote body text, from YouVersion's `.yv-n.f` marker (footnote body
  /// nested in a `.ft` span) - `null` for a plain text run.
  final String? footnoteText;

  /// Non-`null` marks "start a new poetry line here, indented to this
  /// level" - from YouVersion's USFM poetry classes (`.q1`-`.q4`, `.qc`/
  /// `.qs` collapsed to level 1). Confirmed present in real API output
  /// (Matthew 5:3's Beatitudes render as `.q1`/`.q2` siblings, one verse
  /// spanning both). `0` = no indent (still a line break, e.g. `.qc`).
  final int? lineBreakIndentLevel;
}

/// Section-heading class names YouVersion's passage HTML uses for USFM
/// heading markers - confirmed against `platform-sdk-react`'s
/// `bible-html-transformer.ts` (`s1`/`s2`/`ms`/`sp`/`sr`/`r`).
const _headingClasses = {'s1', 's2', 'ms', 'sp', 'sr', 'r'};

/// USFM poetry-line classes YouVersion's passage HTML uses, mapped to an
/// indent level. `qc` (centered) and `qs` (selah) don't have a real
/// centered/selah rendering here - collapsed to level 0, still a line
/// break (a documented simplification, same spirit as this package's
/// "not a general HTML engine" scope elsewhere).
const _poetryIndentLevels = {'q1': 1, 'q2': 2, 'q3': 3, 'q4': 4, 'qc': 0, 'qs': 0};

/// Parses YouVersion's passage HTML (`BiblePassage.content`, "YVDOM") into
/// an ordered list of [BibleTextBlock]s.
///
/// Recognizes: `.yv-v[v]` verse boundaries, `.yv-vlbl` verse-number labels
/// (consumed here, not emitted as a run - callers render the verse number
/// from [BibleVerseBlock.number] instead), `.wj` words-of-Christ spans
/// (nests, so text inside a `.wj` inside a verse still resolves to that
/// verse), `.yv-n.f` inline footnotes (body text lives in a nested `.ft`
/// span), and section headings. Contract confirmed against
/// `platform-sdk-react`'s `bible-html-transformer.test.ts` fixtures - this
/// package has no fixture of its own to validate against, since neither
/// `developers.youversion.com` nor this repo's own tests ever captured raw
/// passage HTML before this parser was written.
List<BibleTextBlock> parseBibleHtml(String html) {
  final document = html_parser.parse(html);
  final blocks = <BibleTextBlock>[];
  final verseBlocksByNumber = <String, BibleVerseBlock>{};
  var currentVerseNumber = '';

  void appendRun(BibleTextRun run) {
    var block = verseBlocksByNumber[currentVerseNumber];
    if (block == null) {
      block = BibleVerseBlock(currentVerseNumber, <BibleTextRun>[]);
      verseBlocksByNumber[currentVerseNumber] = block;
      blocks.add(block);
    }
    block.runs.add(run);
  }

  void walk(dom.Node node, {required bool inWordsOfChrist}) {
    if (node is dom.Text) {
      // Skip pure formatting whitespace between block-level tags (the
      // source HTML is indented for readability) - real content always
      // has non-whitespace, so this never drops an intentional blank run.
      if (node.text.trim().isNotEmpty) {
        appendRun(BibleTextRun(text: node.text, isWordsOfChrist: inWordsOfChrist));
      }
      return;
    }
    if (node is! dom.Element) return;

    final classes = node.classes;
    if (classes.any(_headingClasses.contains)) {
      final text = node.text.trim();
      if (text.isNotEmpty) blocks.add(BibleHeadingBlock(text));
      return;
    }
    if (classes.contains('yv-v')) {
      currentVerseNumber = node.attributes['v'] ?? currentVerseNumber;
      for (final child in node.nodes) {
        walk(child, inWordsOfChrist: inWordsOfChrist);
      }
      return;
    }
    if (classes.contains('yv-vlbl')) {
      // Verse-number label - the caller renders this from
      // `BibleVerseBlock.number` instead, so its text is dropped here.
      return;
    }
    if (classes.contains('yv-n') && (classes.contains('f') || classes.contains('x'))) {
      final footnoteText = node.querySelector('.ft')?.text.trim() ?? node.text.trim();
      if (footnoteText.isNotEmpty) {
        appendRun(BibleTextRun(text: '', footnoteText: footnoteText));
      }
      return;
    }
    final poetryClass = classes.firstWhere((c) => _poetryIndentLevels.containsKey(c), orElse: () => '');
    if (poetryClass.isNotEmpty) {
      // Emit the line break *after* this line's own content (not before) -
      // a poetry line's own verse marker (if any) lives inside it, so the
      // verse number isn't known yet on entry. Appending after means the
      // break always lands under the verse that line actually belongs to.
      for (final child in node.nodes) {
        walk(child, inWordsOfChrist: inWordsOfChrist);
      }
      appendRun(BibleTextRun(text: '', lineBreakIndentLevel: _poetryIndentLevels[poetryClass]));
      return;
    }
    final woc = inWordsOfChrist || classes.contains('wj');
    for (final child in node.nodes) {
      walk(child, inWordsOfChrist: woc);
    }
  }

  for (final child in document.body?.nodes ?? const <dom.Node>[]) {
    walk(child, inWordsOfChrist: false);
  }

  return blocks;
}

/// Plain text of a single verse (its local number, e.g. `"16"` - not the
/// full USFM id) within [html] - every run's text joined with a space,
/// footnote-marker/line-break runs (empty [BibleTextRun.text]) skipped, and
/// a poetry line break becomes a newline instead of a space. `null` if
/// [verseNumber] isn't present. For copy/share actions - the caller
/// already has [content] rendered via [parseBibleHtml] for display, this
/// is the same parse used to get one verse's text back out as a string.
String? extractVersePlainText(String html, String verseNumber) {
  final block = parseBibleHtml(html).whereType<BibleVerseBlock>().where((b) => b.number == verseNumber).firstOrNull;
  if (block == null) return null;

  final buffer = StringBuffer();
  for (final run in block.runs) {
    if (run.lineBreakIndentLevel != null) {
      buffer.writeln();
    } else if (run.text.isNotEmpty) {
      if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) buffer.write(' ');
      buffer.write(run.text.trim());
    }
  }
  return buffer.toString().trim();
}
