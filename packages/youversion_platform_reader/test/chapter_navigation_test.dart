import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';

BibleVersionIndex _index() {
  return BibleVersionIndex.fromJson({
    'text_direction': 'ltr',
    'books': [
      {
        'id': 'GEN',
        'title': 'Genesis',
        // Real shape confirmed live against GET /v1/bibles/111/index and
        // /206/index - `id` on both the intro and each chapter is the
        // bare local id ("INTRO"/"1"/"2"...), `passage_id` is the real
        // full USFM id `getPassage` actually accepts ("GEN.INTRO"/
        // "GEN.1"/"GEN.2"...). Using the bare `id` as a chapterId (as
        // this test fixture used to, before this was caught) 404s against
        // the real API - see docs/DECISIONS.md.
        'intro': {'id': 'INTRO', 'passage_id': 'GEN.INTRO', 'title': 'Intro'},
        'chapters': [
          {'id': '1', 'passage_id': 'GEN.1'},
          {'id': '2', 'passage_id': 'GEN.2'},
        ],
      },
      {
        'id': 'EXO',
        'title': 'Exodus',
        'chapters': [
          {'id': '1', 'passage_id': 'EXO.1'},
        ],
      },
    ],
  });
}

void main() {
  test('next() moves within a book, using the real passage id', () {
    expect(ChapterNavigation.next(_index(), 'GEN.1'), 'GEN.2');
  });

  test('next() crosses into the next book', () {
    expect(ChapterNavigation.next(_index(), 'GEN.2'), 'EXO.1');
  });

  test('next() returns null at the very last chapter', () {
    expect(ChapterNavigation.next(_index(), 'EXO.1'), isNull);
  });

  test('previous() falls back to the book intro before chapter 1, using the real passage id', () {
    expect(ChapterNavigation.previous(_index(), 'GEN.1'), 'GEN.INTRO');
  });

  test('previous() crosses into the previous book last chapter', () {
    expect(ChapterNavigation.previous(_index(), 'EXO.1'), 'GEN.2');
  });

  test('next() from the intro goes to chapter 1', () {
    expect(ChapterNavigation.next(_index(), 'GEN.INTRO'), 'GEN.1');
  });

  test('previous() from the intro crosses into the previous book', () {
    final index = BibleVersionIndex.fromJson({
      'books': [
        {
          'id': 'GEN',
          'chapters': [
            {'id': '1', 'passage_id': 'GEN.1'},
          ],
        },
        {
          'id': 'EXO',
          'intro': {'id': 'INTRO', 'passage_id': 'EXO.INTRO'},
          'chapters': [
            {'id': '1', 'passage_id': 'EXO.1'},
          ],
        },
      ],
    });
    expect(ChapterNavigation.previous(index, 'EXO.INTRO'), 'GEN.1');
  });

  test('a chapter with no passage_id falls back to its bare id', () {
    final index = BibleVersionIndex.fromJson({
      'books': [
        {
          'id': 'EXO',
          'chapters': [
            {'id': 'EXO.1'},
          ],
        },
      ],
    });
    expect(ChapterNavigation.previous(index, 'EXO.1'), isNull);
  });
}
