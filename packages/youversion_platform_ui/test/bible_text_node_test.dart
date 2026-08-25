import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_ui/src/rendering/bible_text_node.dart';

void main() {
  group('extractVersePlainText', () {
    test('returns just one verse\'s text, ignoring siblings', () {
      const html = '''
        <div class="p">
          <span class="yv-v" v="1"></span><span class="yv-vlbl">1</span>Verse one text.
        </div>
        <div class="p">
          <span class="yv-v" v="2"></span><span class="yv-vlbl">2</span>Verse two text.
        </div>
      ''';

      expect(extractVersePlainText(html, '2'), 'Verse two text.');
    });

    test('returns null for a verse number not present', () {
      const html = '<span class="yv-v" v="1"></span>Verse one text.';

      expect(extractVersePlainText(html, '99'), isNull);
    });
  });

  group('parseBibleHtml', () {
    test('wraps a single verse into one BibleVerseBlock', () {
      const html = '''
        <div class="p">
          <span class="yv-v" v="1"></span><span class="yv-vlbl">1</span>Verse one text.
        </div>
      ''';

      final blocks = parseBibleHtml(html);

      expect(blocks, hasLength(1));
      final block = blocks.single as BibleVerseBlock;
      expect(block.number, '1');
      expect(block.runs.map((r) => r.text).join().trim(), 'Verse one text.');
      expect(block.runs.every((r) => !r.isWordsOfChrist), isTrue);
    });

    test('splits multiple verses into separate blocks, in order', () {
      const html = '''
        <div class="p">
          <span class="yv-v" v="1"></span><span class="yv-vlbl">1</span>Verse one text.
        </div>
        <div class="p">
          <span class="yv-v" v="2"></span><span class="yv-vlbl">2</span>Verse two text.
        </div>
      ''';

      final blocks = parseBibleHtml(html).cast<BibleVerseBlock>();

      expect(blocks.map((b) => b.number), ['1', '2']);
      expect(blocks.map((b) => b.runs.map((r) => r.text).join().trim()), [
        'Verse one text.',
        'Verse two text.',
      ]);
    });

    test('a heading between two verses is its own block, not part of either verse', () {
      const html = '''
        <div class="p">
          <span class="yv-v" v="1"></span><span class="yv-vlbl">1</span>Text before heading
        </div>
        <div class="s1">A Heading</div>
        <div class="p">
          <span class="yv-v" v="2"></span><span class="yv-vlbl">2</span>Text after heading
        </div>
      ''';

      final blocks = parseBibleHtml(html);

      expect(blocks, hasLength(3));
      expect(blocks[0], isA<BibleVerseBlock>());
      expect(blocks[1], isA<BibleHeadingBlock>());
      expect((blocks[1] as BibleHeadingBlock).text, 'A Heading');
      expect(blocks[2], isA<BibleVerseBlock>());
    });

    test('marks text inside a .wj span as words of Christ', () {
      const html = '''
        <div class="p">
          <span class="yv-v" v="1"></span><span class="yv-vlbl">1</span><span class="wj">Jesus said</span> this.
        </div>
      ''';

      final blocks = parseBibleHtml(html).cast<BibleVerseBlock>();

      final wocRun = blocks.single.runs.firstWhere((r) => r.text.contains('Jesus said'));
      expect(wocRun.isWordsOfChrist, isTrue);
      final plainRun = blocks.single.runs.firstWhere((r) => r.text.contains('this.'));
      expect(plainRun.isWordsOfChrist, isFalse);
    });

    test('extracts footnote body text from a .yv-n.f marker, without emitting visible text for it', () {
      const html = '''
        <div class="p">
          <span class="yv-v" v="1"></span><span class="yv-vlbl">1</span>Verse text<span class="yv-n f"><span class="ft">Verse note</span></span>.
        </div>
      ''';

      final blocks = parseBibleHtml(html).cast<BibleVerseBlock>();

      final footnoteRun = blocks.single.runs.firstWhere((r) => r.footnoteText != null);
      expect(footnoteRun.footnoteText, 'Verse note');
      expect(footnoteRun.text, isEmpty);
      expect(blocks.single.runs.map((r) => r.text).join(), isNot(contains('Verse note')));
    });

    test('groups text with no preceding verse marker under an empty-number block', () {
      const html = '<div class="ip">Some intro text.</div>';

      final blocks = parseBibleHtml(html).cast<BibleVerseBlock>();

      expect(blocks.single.number, isEmpty);
      expect(blocks.single.runs.map((r) => r.text).join().trim(), 'Some intro text.');
    });
  });

  group('parseBibleHtml against real API responses', () {
    // Captured 2026-08-24 from GET /v1/bibles/206/passages/{id}?format=html
    // (bible 206 = WEBUS, public domain) - real content, not paraphrased
    // fixtures, to close the loop on whether the react SDK's transformer
    // test fixtures actually match what the live API sends.
    test('a single verse (John 3:1)', () {
      const content = '<div><div class="p"><span class="yv-v" v="1"></span><span class="yv-vlbl">1</span>'
          'Now there was a man of the Pharisees named Nicodemus, a ruler of the Jews. </div></div>';

      final blocks = parseBibleHtml(content).cast<BibleVerseBlock>();

      expect(blocks.single.number, '1');
      expect(
        blocks.single.runs.map((r) => r.text).join().trim(),
        'Now there was a man of the Pharisees named Nicodemus, a ruler of the Jews.',
      );
    });

    test(
        'words of Christ continuing across a sibling <div> (poetry lines), '
        'plus a cross-reference with no .ft span', () {
      const content = '<div>'
          '<div class="q1"><span class="yv-v" v="3"></span><span class="yv-vlbl">3</span> '
          '<span class="wj">“Blessed are the poor in spirit,</span></div>'
          '<div class="q2"><span class="wj">for theirs is the Kingdom of Heaven.</span>'
          '<span class="yv-n x"><span class="ref" usfm="ISA.57.15">Isaiah 57:15</span>; '
          '<span class="ref" usfm="ISA.66.2">66:2</span></span></div>'
          '</div>';

      final blocks = parseBibleHtml(content).cast<BibleVerseBlock>();

      // One verse block even though the content spans two sibling <div>s -
      // no second .yv-v marker appears, so the verse number "sticks".
      expect(blocks, hasLength(1));
      expect(blocks.single.number, '3');
      final wocText = blocks.single.runs.where((r) => r.isWordsOfChrist).map((r) => r.text).join();
      expect(wocText, '“Blessed are the poor in spirit,for theirs is the Kingdom of Heaven.');
      // .yv-n.x has no nested .ft (unlike .yv-n.f) - falls back to the
      // marker's own text, picking up both cross-references.
      final noteRun = blocks.single.runs.firstWhere((r) => r.footnoteText != null);
      expect(noteRun.footnoteText, 'Isaiah 57:15; 66:2');
      // Two poetry lines (.q1 then .q2) -> one line-break run trailing
      // each line (a break is emitted once the line it belongs to is
      // fully processed, not before - a leading break for .q1 would
      // misattribute it to whatever verse preceded this one).
      final lineBreaks = blocks.single.runs.where((r) => r.lineBreakIndentLevel != null).toList();
      expect(lineBreaks.map((r) => r.lineBreakIndentLevel), [1, 2]);
      final wocIndex = blocks.single.runs.indexWhere((r) => r.isWordsOfChrist);
      final firstBreakIndex = blocks.single.runs.indexOf(lineBreaks.first);
      expect(firstBreakIndex, greaterThan(wocIndex));
    });
  });
}
