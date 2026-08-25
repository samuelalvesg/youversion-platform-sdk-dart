import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

void main() {
  group('YouVersionContentClient', () {
    test('listBibles sends X-YVP-App-Key and decodes the paginated collection', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-YVP-App-Key'], 'my-app-key');
        expect(request.url.path, '/v1/bibles');
        expect(request.url.queryParameters['language_ranges[]'], 'en');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 111,
                'abbreviation': 'NIV',
                'title': 'New International Version',
                'language_tag': 'en',
              },
            ],
            'next_page_token': 'abc',
            'total_size': 42,
          }),
          200,
        );
      });

      final content = YouVersionContentClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final result = await content.listBibles(languageRanges: ['en']);

      expect(result.data, hasLength(1));
      expect(result.data.first.id, 111);
      expect(result.data.first.title, 'New International Version');
      expect(result.nextPageToken, 'abc');
      expect(result.totalSize, 42);
      expect(result.hasNextPage, isTrue);
    });

    test('listBibles without languages uses language_ranges[]=*', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['language_ranges[]'], '*');
        return http.Response(jsonEncode({'data': <dynamic>[]}), 200);
      });

      final content = YouVersionContentClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      await content.listBibles();
    });

    test('getPassage decodes passage content (data envelope)', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/bibles/111/passages/JHN.3.16');
        expect(request.url.queryParameters['format'], 'html');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 'JHN.3.16',
              'content': 'For God so loved the world...',
              'reference': 'John 3:16',
            },
          }),
          200,
        );
      });

      final content = YouVersionContentClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final passage = await content.getPassage(
        bibleId: 111,
        passageId: 'JHN.3.16',
      );

      expect(passage.reference, 'John 3:16');
    });

    test('getIndex decodes text_direction and nested books', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/bibles/111/index');
        return http.Response(
          jsonEncode({
            'data': {
              'text_direction': 'rtl',
              'books': [
                {'id': 'GEN', 'title': 'Genesis'},
              ],
            },
          }),
          200,
        );
      });

      final content = YouVersionContentClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final index = await content.getIndex(111);

      expect(index.textDirection, 'rtl');
      expect(index.books, hasLength(1));
      expect(index.books!.first.id, 'GEN');
    });

    test('getBook fetches a single item', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/bibles/111/books/MAT');
        return http.Response(
          jsonEncode({
            'data': {'id': 'MAT', 'title': 'Matthew'},
          }),
          200,
        );
      });

      final content = YouVersionContentClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final book = await content.getBook(bibleId: 111, bookUsfm: 'MAT');

      expect(book.title, 'Matthew');
    });

    test('concurrent getBible calls for the same id share one HTTP request', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return http.Response(
          jsonEncode({
            'data': {'id': 206, 'title': 'World English Bible'},
          }),
          200,
        );
      });

      final content = YouVersionContentClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final results = await Future.wait([content.getBible(206), content.getBible(206)]);

      expect(callCount, 1);
      expect(results[0].title, 'World English Bible');
      expect(results[1].title, 'World English Bible');
    });

    test('getBible called again after completion is served from cache, not a new request', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode({
            'data': {'id': 206, 'title': 'World English Bible'},
          }),
          200,
        );
      });

      final content = YouVersionContentClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      await content.getBible(206);
      await content.getBible(206);

      expect(callCount, 1);
    });

    test('listBooks with different bible ids does not share a cache entry', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response(jsonEncode({'data': <dynamic>[]}), 200);
      });

      final content = YouVersionContentClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      await content.listBooks(111);
      await content.listBooks(206);

      expect(callCount, 2);
    });

    test('a failed request is not cached - a later retry fires a real request again', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) return http.Response('server error', 500);
        return http.Response(
          jsonEncode({
            'data': {'id': 206, 'title': 'World English Bible'},
          }),
          200,
        );
      });

      final content = YouVersionContentClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      await expectLater(content.getBible(206), throwsA(isA<YouVersionException>()));
      final bible = await content.getBible(206);

      expect(callCount, 2);
      expect(bible.title, 'World English Bible');
    });

    test('close() clears the cache - a later call fires a new request', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode({
            'data': {'id': 206, 'title': 'World English Bible'},
          }),
          200,
        );
      });

      final content = YouVersionContentClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      await content.getBible(206);
      content.close();
      await content.getBible(206);

      expect(callCount, 2);
    });

    test('HTTP 401 (missing/invalid App Key) throws YouVersionException with missingAuthentication', () async {
      final mockClient = MockClient((request) async {
        return http.Response('unauthorized', 401);
      });

      final content = YouVersionContentClient(
        appKey: 'invalid-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      try {
        await content.listBibles(languageRanges: ['en']);
        fail('expected a YouVersionException');
      } on YouVersionException catch (e) {
        expect(e.reason, YouVersionErrorReason.missingAuthentication);
      }
    });
  });
}
