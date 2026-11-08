import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

YouVersionSearchClient _client(http.Response Function(http.Request request) respond) {
  return YouVersionSearchClient(
    appKey: 'my-app-key',
    httpClient: YouVersionHttpClient(client: MockClient((request) async => respond(request))),
  );
}

http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);

void main() {
  group('searchUnified', () {
    test('sends repeated language_ranges[] and fields[] and decodes verses, topics and metadata', () async {
      late Uri seen;
      late Map<String, String> headers;
      final client = _client((request) {
        seen = request.url;
        headers = request.headers;
        return _json({
          'verses': [
            {'reference': 'JHN.3.16'},
            {'reference': '1CO.13.4'},
          ],
          'topics': [
            {
              'id': 42,
              'text': 'love',
              'subtopics': ['trust', 'belief'],
            },
          ],
          'user_intent': 'topical',
          'did_you_mean': ['lover'],
          'search_instead_for': null,
        });
      });

      final result = await client.searchUnified(
        query: 'love',
        bibleId: 3034,
        languageRanges: ['en', 'es'],
        userIntent: SearchUserIntent.topical,
        fields: [SearchField.verses, SearchField.topics],
      );

      expect(seen.path, '/v1/search-unified');
      expect(seen.queryParametersAll['query'], ['love']);
      expect(seen.queryParametersAll['bible_id'], ['3034']);
      expect(seen.queryParametersAll['language_ranges[]'], ['en', 'es']);
      expect(seen.queryParametersAll['fields[]'], ['verses', 'topics']);
      expect(seen.queryParametersAll['user_intent'], ['topical']);
      expect(headers['X-YVP-App-Key'], 'my-app-key');
      expect(result.verses.map((v) => v.reference), ['JHN.3.16', '1CO.13.4']);
      expect(result.topics.single.text, 'love');
      expect(result.topics.single.subtopics, ['trust', 'belief']);
      expect(result.info.userIntent, SearchUserIntent.topical);
      expect(result.info.didYouMean, ['lover']);
      expect(result.info.searchInsteadFor, isNull);
    });

    test('an empty 200 answer decodes to empty lists, not an error', () async {
      final client = _client((_) => _json({'verses': [], 'topics': [], 'did_you_mean': [], 'search_instead_for': null}));
      final result = await client.searchUnified(query: 'zzzz', bibleId: 1, languageRanges: ['en']);
      expect(result.verses, isEmpty);
      expect(result.topics, isEmpty);
    });
  });

  group('searchVerses', () {
    test('decodes a page, exposes the next token and sends it back', () async {
      final requests = <Uri>[];
      final client = _client((request) {
        requests.add(request.url);
        final hasToken = request.url.queryParameters.containsKey('page_token');
        return _json({
          'verses': [
            {'reference': hasToken ? '1JN.4.8' : 'JHN.3.16'},
          ],
          'user_intent': 'text',
          'did_you_mean': [],
          'search_instead_for': 'jesus',
          'next_page_token': hasToken ? null : 'abc==',
        });
      });

      final first = await client.searchVerses(query: 'jees', bibleId: 3034, pageSize: 25);
      expect(first.hasNextPage, isTrue);
      expect(first.info.searchInsteadFor, 'jesus');
      expect(first.info.userIntent, SearchUserIntent.text);

      final second = await client.searchVerses(query: 'jees', bibleId: 3034, pageToken: first.nextPageToken);
      expect(second.hasNextPage, isFalse);
      expect(second.verses.single.reference, '1JN.4.8');
      expect(requests.first.queryParameters['page_size'], '25');
      expect(requests.last.queryParameters['page_token'], 'abc==');
    });

    test('a 404 means the Bible is not available to the app', () async {
      final client = _client((_) => _json({'error': 'Bible version 9 not found'}, 404));
      await expectLater(
        client.searchVerses(query: 'love', bibleId: 9),
        throwsA(
          isA<YouVersionException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.reason, 'reason', YouVersionErrorReason.notPermitted),
        ),
      );
    });

    test('a 429 carries Retry-After', () async {
      final client = _client((_) => http.Response('Rate limit exceeded.', 429, headers: {'retry-after': '30'}));
      await expectLater(
        client.searchVerses(query: 'love', bibleId: 1),
        throwsA(
          isA<YouVersionException>()
              .having((e) => e.reason, 'reason', YouVersionErrorReason.rateLimited)
              .having((e) => e.retryAfter, 'retryAfter', const Duration(seconds: 30)),
        ),
      );
    });

    test('rejects out-of-range arguments before any request', () {
      var calls = 0;
      final client = _client((_) {
        calls++;
        return _json({});
      });
      expect(() => client.searchVerses(query: '', bibleId: 1), throwsArgumentError);
      expect(() => client.searchVerses(query: 'x' * 101, bibleId: 1), throwsArgumentError);
      expect(() => client.searchVerses(query: 'love', bibleId: 1, pageSize: 0), throwsArgumentError);
      expect(() => client.searchVerses(query: 'love', bibleId: 1, pageSize: 100), throwsArgumentError);
      expect(calls, 0);
    });
  });

  group('searchTopics', () {
    test('decodes topics with a nullable id and total_size', () async {
      final client = _client((request) {
        expect(request.url.path, '/v1/search-topics');
        return _json({
          'topics': [
            {'id': null, 'text': 'faith', 'subtopics': []},
          ],
          'did_you_mean': [],
          'search_instead_for': null,
          'total_size': 1,
        });
      });

      final result = await client.searchTopics(query: 'faith', languageRanges: ['en']);

      expect(result.topics.single.id, isNull);
      expect(result.totalSize, 1);
      expect(result.info.userIntent, isNull);
    });
  });

  group('search-queries', () {
    test('suggestQueries sends query and decodes the data envelope', () async {
      late Uri seen;
      final client = _client((request) {
        seen = request.url;
        return _json({
          'data': [
            {'text': 'love', 'source': 'trending'},
            {'text': 'loneliness'},
          ],
        });
      });

      final result = await client.suggestQueries(query: 'lo', languageRanges: ['en']);

      expect(seen.queryParameters['query'], 'lo');
      expect(seen.queryParameters.containsKey('trending'), isFalse);
      expect(result.map((s) => s.text), ['love', 'loneliness']);
      expect(result.last.source, isNull);
    });

    test('trendingQueries sends trending=true and no query', () async {
      late Uri seen;
      final client = _client((request) {
        seen = request.url;
        return _json({'data': []});
      });

      await client.trendingQueries(languageRanges: ['*']);

      expect(seen.queryParameters['trending'], 'true');
      expect(seen.queryParameters.containsKey('query'), isFalse);
    });

    test('a 204 with an empty body is an empty list', () async {
      final client = _client((_) => http.Response('', 204));
      expect(await client.trendingQueries(languageRanges: ['en']), isEmpty);
      expect(await client.suggestQueries(query: 'zz', languageRanges: ['en']), isEmpty);
    });
  });

  test('an unknown user_intent falls back to unknown instead of failing', () {
    expect(SearchUserIntent.fromWire('something-new'), SearchUserIntent.unknown);
    expect(SearchUserIntent.fromWire(null), isNull);
    expect(SearchUserIntent.fromWire('reference'), SearchUserIntent.reference);
  });
}
