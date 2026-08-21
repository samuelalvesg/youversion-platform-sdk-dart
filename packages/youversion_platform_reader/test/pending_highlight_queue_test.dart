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
}
