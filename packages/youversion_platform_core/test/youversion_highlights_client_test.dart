import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

void main() {
  group('YouVersionHighlightsClient', () {
    test('listHighlights sends Bearer and bible_id/passage_id in the query', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/highlights');
        expect(request.url.queryParameters['bible_id'], '111');
        expect(request.url.queryParameters['passage_id'], 'MAT.1.1');
        expect(request.headers['Authorization'], 'Bearer access-1');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'hl-1',
                'bible_id': 111,
                'passage_id': 'MAT.1.1',
                'color': 'fffe00',
              },
            ],
          }),
          200,
        );
      });

      final highlights = YouVersionHighlightsClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final result = await highlights.listHighlights(
        userAccessToken: 'access-1',
        bibleId: 111,
        passageId: 'MAT.1.1',
      );

      expect(result, hasLength(1));
      expect(result.first.color, 'fffe00');
    });

    test('listHighlights treats 204 as an empty list', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 204);
      });

      final highlights = YouVersionHighlightsClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final result = await highlights.listHighlights(
        userAccessToken: 'access-1',
        bibleId: 111,
      );

      expect(result, isEmpty);
    });

    test('createHighlight sends request_id (uuid) and normalizes the color', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/highlights');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(
            body['request_id'],
            matches(RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            )));
        final highlight = body['highlight'] as Map<String, dynamic>;
        expect(highlight['color'], 'fffe00');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 'hl-1',
              'bible_id': 111,
              'passage_id': 'MAT.1.1',
              'color': 'fffe00',
            },
          }),
          201,
        );
      });

      final highlights = YouVersionHighlightsClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final result = await highlights.createHighlight(
        userAccessToken: 'access-1',
        bibleId: 111,
        passageId: 'MAT.1.1',
        color: '#FFFE00',
      );

      expect(result.id, 'hl-1');
    });

    test('createHighlight/listHighlights tolerate a null "id" - confirmed live, the server sends this', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': {
              // No "id" key at all - matches Kotlin's own model
              // (`id: String? = null`), and a real create/list response
              // observed live. Previously crashed `Highlight.fromJson`
              // with an uncaught type-cast error.
              'bible_id': 111,
              'passage_id': 'MAT.1.1',
              'color': 'fffe00',
            },
          }),
          201,
        );
      });

      final highlights = YouVersionHighlightsClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final result = await highlights.createHighlight(
        userAccessToken: 'access-1',
        bibleId: 111,
        passageId: 'MAT.1.1',
        color: 'fffe00',
      );

      expect(result.id, isNull);
      expect(result.color, 'fffe00');
    });

    test('createHighlight 403 throws notPermitted', () async {
      final mockClient = MockClient((request) async {
        return http.Response('forbidden', 403);
      });

      final highlights = YouVersionHighlightsClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      try {
        await highlights.createHighlight(
          userAccessToken: 'access-1',
          bibleId: 111,
          passageId: 'MAT.1.1',
          color: 'fffe00',
        );
        fail('should have thrown');
      } on YouVersionException catch (e) {
        expect(e.reason, YouVersionErrorReason.notPermitted);
      }
    });

    test('deleteHighlight uses passageId in the path, bible_id in the query', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/v1/highlights/MAT.1.1');
        expect(request.url.queryParameters['bible_id'], '111');
        return http.Response('', 200);
      });

      final highlights = YouVersionHighlightsClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      await highlights.deleteHighlight(
        userAccessToken: 'access-1',
        bibleId: 111,
        passageId: 'MAT.1.1',
      );
    });
  });
}
