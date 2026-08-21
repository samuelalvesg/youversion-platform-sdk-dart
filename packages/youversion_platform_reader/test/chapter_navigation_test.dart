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
        'intro': {'id': 'GEN.intro', 'content': ''},
        'chapters': [
          {'id': 'GEN.1', 'passage_id': 'GEN.1'},
          {'id': 'GEN.2', 'passage_id': 'GEN.2'},
        ],
      },
      {
        'id': 'EXO',
        'title': 'Exodus',
        'chapters': [
          {'id': 'EXO.1', 'passage_id': 'EXO.1'},
        ],
      },
    ],
  });
}

void main() {
  test('next() moves within a book', () {
    expect(ChapterNavigation.next(_index(), 'GEN.1'), 'GEN.2');
  });

  test('next() crosses into the next book', () {
    expect(ChapterNavigation.next(_index(), 'GEN.2'), 'EXO.1');
  });

  test('next() returns null at the very last chapter', () {
    expect(ChapterNavigation.next(_index(), 'EXO.1'), isNull);
  });

  test('previous() falls back to the book intro before chapter 1', () {
    expect(ChapterNavigation.previous(_index(), 'GEN.1'), 'GEN.intro');
  });

  test('previous() crosses into the previous book last chapter', () {
    expect(ChapterNavigation.previous(_index(), 'EXO.1'), 'GEN.2');
  });

  test('previous() returns null at the very first chapter with no intro', () {
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
