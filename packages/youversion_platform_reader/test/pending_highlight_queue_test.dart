import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';

void main() {
  test('enqueue then load returns the queued request', () async {
    final storage = InMemoryReaderStorage();
    final queue = PendingHighlightQueue(storage);

    await queue.enqueue(
      const PendingHighlightRequest(bibleId: 111, passageId: 'JHN.3.16', color: 'fffe00'),
    );

    final loaded = await queue.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.passageId, 'JHN.3.16');
  });

  test('load returns empty list when nothing was queued', () async {
    final queue = PendingHighlightQueue(InMemoryReaderStorage());
    expect(await queue.load(), isEmpty);
  });

  group('pendingHighlightsFor', () {
    test('returns only entries matching bibleId and chapter prefix', () async {
      final queue = PendingHighlightQueue(InMemoryReaderStorage());
      await queue.enqueue(const PendingHighlightRequest(bibleId: 1, passageId: 'GEN.1.1', color: 'aaaaaa'));
      await queue.enqueue(const PendingHighlightRequest(bibleId: 1, passageId: 'GEN.1.2', color: 'bbbbbb'));
      // Different chapter, same bible - 'GEN.1' must not prefix-match 'GEN.10.1'.
      await queue.enqueue(const PendingHighlightRequest(bibleId: 1, passageId: 'GEN.10.1', color: 'cccccc'));
      // Different bible, same chapter/verse.
      await queue.enqueue(const PendingHighlightRequest(bibleId: 2, passageId: 'GEN.1.1', color: 'dddddd'));

      final result = await queue.pendingHighlightsFor(bibleId: 1, chapterPassageId: 'GEN.1');

      expect(result, {'GEN.1.1': 'aaaaaa', 'GEN.1.2': 'bbbbbb'});
    });

    test('returns empty map when nothing matches', () async {
      final queue = PendingHighlightQueue(InMemoryReaderStorage());
      expect(await queue.pendingHighlightsFor(bibleId: 1, chapterPassageId: 'GEN.1'), isEmpty);
    });
  });

  group('removePending', () {
    test('drops only the matching bibleId+passageId entry', () async {
      final queue = PendingHighlightQueue(InMemoryReaderStorage());
      await queue.enqueue(const PendingHighlightRequest(bibleId: 1, passageId: 'GEN.1.1', color: 'aaaaaa'));
      await queue.enqueue(const PendingHighlightRequest(bibleId: 1, passageId: 'GEN.1.2', color: 'bbbbbb'));
      // Same passageId, different bible - must survive the removal below.
      await queue.enqueue(const PendingHighlightRequest(bibleId: 2, passageId: 'GEN.1.1', color: 'cccccc'));

      await queue.removePending(bibleId: 1, passageId: 'GEN.1.1');

      final remaining = await queue.load();
      expect(remaining.map((r) => (r.bibleId, r.passageId)), [(1, 'GEN.1.2'), (2, 'GEN.1.1')]);
    });

    test('is a no-op when nothing matches', () async {
      final storage = InMemoryReaderStorage();
      final queue = PendingHighlightQueue(storage);
      await queue.enqueue(const PendingHighlightRequest(bibleId: 1, passageId: 'GEN.1.1', color: 'aaaaaa'));

      await queue.removePending(bibleId: 1, passageId: 'GEN.1.2');

      expect(await queue.load(), hasLength(1));
    });
  });
}
