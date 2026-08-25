import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

Map<String, dynamic> _highlightJson({required int bibleId, required String passageId, required String color}) => {
      'bible_id': bibleId,
      'passage_id': passageId,
      'color': color,
    };

void main() {
  group('YouVersionHighlightsSyncEngine', () {
    test('setHighlight is optimistic - appears locally before the server responds', () async {
      final mockClient = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response(
          jsonEncode({'data': _highlightJson(bibleId: 111, passageId: 'JHN.3.16', color: 'fffe00')}),
          201,
        );
      });

      final engine = YouVersionHighlightsSyncEngine(
        client: YouVersionHighlightsClient(appKey: 'my-app-key', httpClient: YouVersionHttpClient(client: mockClient)),
        accessToken: () => 'access-1',
        backoff: (_) => Duration.zero,
      );

      engine.setHighlight(bibleId: 111, chapterId: 'JHN.3', passageId: 'JHN.3.16', color: 'fffe00');

      final highlights = engine.highlightsForChapter(bibleId: 111, chapterId: 'JHN.3');
      expect(highlights, hasLength(1));
      expect(highlights.first.color, 'fffe00');
      // Not `pendingOperationCount` - like Kotlin's `queuedOperations`,
      // it reads 0 while a batch is claimed/in-flight (the processor
      // empties the queue list synchronously the moment it claims a
      // batch, before any `await` suspends) - `hasPendingOperations` is
      // the one that stays true for the whole in-flight window.
      expect(engine.hasPendingOperations, isTrue);

      engine.close();
    });

    test('a transient failure is retried with backoff and eventually succeeds', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) return http.Response('server error', 500);
        return http.Response(
          jsonEncode({'data': _highlightJson(bibleId: 111, passageId: 'JHN.3.16', color: 'fffe00')}),
          201,
        );
      });

      final engine = YouVersionHighlightsSyncEngine(
        client: YouVersionHighlightsClient(appKey: 'my-app-key', httpClient: YouVersionHttpClient(client: mockClient)),
        accessToken: () => 'access-1',
        backoff: (_) => const Duration(milliseconds: 5),
      );

      engine.setHighlight(bibleId: 111, chapterId: 'JHN.3', passageId: 'JHN.3.16', color: 'fffe00');
      expect(engine.hasPendingOperations, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(callCount, 2);
      expect(engine.pendingOperationCount, 0);
      expect(engine.hasPendingOperations, isFalse);

      engine.close();
    });

    test('a 403 drops the whole batch without retry and reloads the affected chapter', () async {
      var writeCount = 0;
      var listCount = 0;
      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          listCount++;
          return http.Response(jsonEncode({'data': <dynamic>[]}), 200);
        }
        writeCount++;
        return http.Response('forbidden', 403);
      });

      final engine = YouVersionHighlightsSyncEngine(
        client: YouVersionHighlightsClient(appKey: 'my-app-key', httpClient: YouVersionHttpClient(client: mockClient)),
        accessToken: () => 'access-1',
        backoff: (_) => const Duration(milliseconds: 5),
      );

      engine.setHighlight(bibleId: 111, chapterId: 'JHN.3', passageId: 'JHN.3.16', color: 'fffe00');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(writeCount, 1); // rejected once, never retried
      expect(engine.pendingOperationCount, 0);
      expect(engine.failedOperationCount, 1);
      expect(listCount, 1); // reload triggered for the rejected chapter

      engine.close();
    });

    test('ensureLoaded is throttled - a second call within the window fires no new request', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response(jsonEncode({'data': <dynamic>[]}), 200);
      });

      final engine = YouVersionHighlightsSyncEngine(
        client: YouVersionHighlightsClient(appKey: 'my-app-key', httpClient: YouVersionHttpClient(client: mockClient)),
        accessToken: () => 'access-1',
        chapterLoadThrottle: const Duration(milliseconds: 50),
      );

      engine.ensureLoaded(bibleId: 111, chapterId: 'JHN.3');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      engine.ensureLoaded(bibleId: 111, chapterId: 'JHN.3');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(callCount, 1);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      engine.ensureLoaded(bibleId: 111, chapterId: 'JHN.3');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(callCount, 2);

      engine.close();
    });

    test('two concurrent ensureLoaded calls for the same chapter share one in-flight request', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response(jsonEncode({'data': <dynamic>[]}), 200);
      });

      final engine = YouVersionHighlightsSyncEngine(
        client: YouVersionHighlightsClient(appKey: 'my-app-key', httpClient: YouVersionHttpClient(client: mockClient)),
        accessToken: () => 'access-1',
      );

      engine.ensureLoaded(bibleId: 111, chapterId: 'JHN.3');
      engine.ensureLoaded(bibleId: 111, chapterId: 'JHN.3');
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(callCount, 1);

      engine.close();
    });

    test('reset() during a pending retry discards it instead of resending', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response('server error', 500);
      });

      final engine = YouVersionHighlightsSyncEngine(
        client: YouVersionHighlightsClient(appKey: 'my-app-key', httpClient: YouVersionHttpClient(client: mockClient)),
        accessToken: () => 'access-1',
        backoff: (_) => const Duration(milliseconds: 200),
      );

      engine.setHighlight(bibleId: 111, chapterId: 'JHN.3', passageId: 'JHN.3.16', color: 'fffe00');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(callCount, 1); // first attempt already failed, now backing off

      engine.reset();
      expect(engine.pendingOperationCount, 0);
      expect(engine.highlightsForChapter(bibleId: 111, chapterId: 'JHN.3'), isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(callCount, 1); // the backed-off retry never fired again

      engine.close();
    });

    test('close() stops processing - no further requests fire', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response('server error', 500);
      });

      final engine = YouVersionHighlightsSyncEngine(
        client: YouVersionHighlightsClient(appKey: 'my-app-key', httpClient: YouVersionHttpClient(client: mockClient)),
        accessToken: () => 'access-1',
        backoff: (_) => const Duration(milliseconds: 10),
      );

      engine.setHighlight(bibleId: 111, chapterId: 'JHN.3', passageId: 'JHN.3.16', color: 'fffe00');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      engine.close();

      final countAtClose = callCount;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(callCount, countAtClose);
    });

    test('removeHighlight removes the local optimistic entry immediately', () async {
      final mockClient = MockClient((request) async => http.Response('', 200));
      final engine = YouVersionHighlightsSyncEngine(
        client: YouVersionHighlightsClient(appKey: 'my-app-key', httpClient: YouVersionHttpClient(client: mockClient)),
        accessToken: () => 'access-1',
        backoff: (_) => Duration.zero,
      );

      engine.setHighlight(bibleId: 111, chapterId: 'JHN.3', passageId: 'JHN.3.16', color: 'fffe00');
      expect(engine.highlightsForChapter(bibleId: 111, chapterId: 'JHN.3'), hasLength(1));

      engine.removeHighlight(bibleId: 111, chapterId: 'JHN.3', passageId: 'JHN.3.16');
      expect(engine.highlightsForChapter(bibleId: 111, chapterId: 'JHN.3'), isEmpty);

      engine.close();
    });

    test('a 404 on delete counts as success, not a failure to retry', () async {
      var deleteCount = 0;
      final mockClient = MockClient((request) async {
        if (request.method == 'DELETE') {
          deleteCount++;
          return http.Response('not found', 404);
        }
        return http.Response(
          jsonEncode({'data': _highlightJson(bibleId: 111, passageId: 'JHN.3.16', color: 'fffe00')}),
          201,
        );
      });

      final engine = YouVersionHighlightsSyncEngine(
        client: YouVersionHighlightsClient(appKey: 'my-app-key', httpClient: YouVersionHttpClient(client: mockClient)),
        accessToken: () => 'access-1',
        backoff: (_) => const Duration(milliseconds: 5),
      );

      // Already-server-backed, so `removeHighlight` actually calls DELETE
      // (not just clearing an optimistic local-only entry).
      engine.setHighlight(bibleId: 111, chapterId: 'JHN.3', passageId: 'JHN.3.16', color: 'fffe00');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      engine.removeHighlight(bibleId: 111, chapterId: 'JHN.3', passageId: 'JHN.3.16');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(deleteCount, 1); // not retried
      expect(engine.pendingOperationCount, 0);
      expect(engine.failedOperationCount, 0);
      expect(engine.highlightsForChapter(bibleId: 111, chapterId: 'JHN.3'), isEmpty);

      engine.close();
    });
  });
}
