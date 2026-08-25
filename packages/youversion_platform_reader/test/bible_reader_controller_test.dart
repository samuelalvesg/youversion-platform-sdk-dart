import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';

BibleVersionIndex _index() {
  return BibleVersionIndex.fromJson({
    'text_direction': 'ltr',
    'books': [
      {
        'id': 'JHN',
        'title': 'John',
        'chapters': [
          {'id': 'JHN.3', 'passage_id': 'JHN.3'},
        ],
      },
    ],
  });
}

BibleReaderController _controller() {
  return BibleReaderController(
    content: YouVersionContentClient(appKey: 'test-key'),
    bible: Bible.fromJson({'id': 206}),
    index: _index(),
    initialChapterId: 'JHN.3',
  );
}

void main() {
  test('selectVerse sets selectedVerseId; tapping the same verse again deselects it', () {
    final controller = _controller();

    controller.selectVerse('JHN.3.16');
    expect(controller.selectedVerseId, 'JHN.3.16');

    controller.selectVerse('JHN.3.16');
    expect(controller.selectedVerseId, isNull);
  });

  test('selectVerse switches selection to a different verse without toggling off first', () {
    final controller = _controller();

    controller.selectVerse('JHN.3.16');
    controller.selectVerse('JHN.3.17');

    expect(controller.selectedVerseId, 'JHN.3.17');
  });

  test('setVerseHighlights keys by passageId', () {
    final controller = _controller();

    controller.setVerseHighlights([
      Highlight(id: '1', bibleId: 206, passageId: 'JHN.3.16', color: 'fffe00'),
      Highlight(id: '2', bibleId: 206, passageId: 'JHN.3.17', color: '5dff79'),
    ]);

    expect(controller.verseHighlights, {'JHN.3.16': 'fffe00', 'JHN.3.17': '5dff79'});
  });

  test('putVerseHighlight adds/overwrites one entry without dropping others', () {
    final controller = _controller();
    controller.setVerseHighlights([Highlight(id: '1', bibleId: 206, passageId: 'JHN.3.16', color: 'fffe00')]);

    controller.putVerseHighlight('JHN.3.17', '5dff79');

    expect(controller.verseHighlights, {'JHN.3.16': 'fffe00', 'JHN.3.17': '5dff79'});
  });

  test('removeVerseHighlight drops one entry without affecting others', () {
    final controller = _controller();
    controller.setVerseHighlights([
      Highlight(id: '1', bibleId: 206, passageId: 'JHN.3.16', color: 'fffe00'),
      Highlight(id: '2', bibleId: 206, passageId: 'JHN.3.17', color: '5dff79'),
    ]);

    controller.removeVerseHighlight('JHN.3.16');

    expect(controller.verseHighlights, {'JHN.3.17': '5dff79'});
  });

  test('goToChapter clears selection and highlights', () async {
    final controller = _controller();
    controller.selectVerse('JHN.3.16');
    controller.setVerseHighlights([Highlight(id: '1', bibleId: 206, passageId: 'JHN.3.16', color: 'fffe00')]);

    await controller.goToChapter('JHN.4');

    expect(controller.selectedVerseId, isNull);
    expect(controller.verseHighlights, isEmpty);
  });
}
