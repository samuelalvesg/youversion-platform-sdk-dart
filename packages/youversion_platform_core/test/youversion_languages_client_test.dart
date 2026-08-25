import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

void main() {
  group('YouVersionLanguagesClient', () {
    test('listLanguages decodes default_bible_version_id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/languages');
        expect(request.url.queryParameters['country'], 'BR');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'por',
                'language': 'Portuguese',
                'text_direction': 'ltr',
                'default_bible_version_id': 1608,
              },
            ],
          }),
          200,
        );
      });

      final languages = YouVersionLanguagesClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final result = await languages.listLanguages(country: 'BR');

      expect(result.data.first.id, 'por');
      expect(result.data.first.defaultBibleVersionId, 1608);
      expect(result.data.first.isRightToLeft, isFalse);
    });

    test('getLanguage fetches a single item', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/languages/por');
        return http.Response(
          jsonEncode({
            'data': {'id': 'por', 'text_direction': 'ltr'},
          }),
          200,
        );
      });

      final languages = YouVersionLanguagesClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final language = await languages.getLanguage('por');

      expect(language.id, 'por');
    });

    test('concurrent listLanguages calls with the same country share one HTTP request', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 'por', 'text_direction': 'ltr'},
            ],
          }),
          200,
        );
      });

      final languages = YouVersionLanguagesClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final results = await Future.wait([
        languages.listLanguages(country: 'BR'),
        languages.listLanguages(country: 'BR'),
      ]);

      expect(callCount, 1);
      expect(results[0].data.first.id, 'por');
      expect(results[1].data.first.id, 'por');
    });

    test('listLanguages with a different country does not share a cache entry', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response(jsonEncode({'data': <dynamic>[]}), 200);
      });

      final languages = YouVersionLanguagesClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      await languages.listLanguages(country: 'BR');
      await languages.listLanguages(country: 'US');

      expect(callCount, 2);
    });

    test('getLanguage called again after completion is served from cache, not a new request', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode({
            'data': {'id': 'por', 'text_direction': 'ltr'},
          }),
          200,
        );
      });

      final languages = YouVersionLanguagesClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      await languages.getLanguage('por');
      await languages.getLanguage('por');

      expect(callCount, 1);
    });

    test('a failed request is not cached - a later retry fires a real request again', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) return http.Response('server error', 500);
        return http.Response(
          jsonEncode({
            'data': {'id': 'por', 'text_direction': 'ltr'},
          }),
          200,
        );
      });

      final languages = YouVersionLanguagesClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      await expectLater(languages.getLanguage('por'), throwsA(isA<YouVersionException>()));
      final language = await languages.getLanguage('por');

      expect(callCount, 2);
      expect(language.id, 'por');
    });

    test('401 (missing/invalid App Key) maps to missingAuthentication', () async {
      final mockClient = MockClient((request) async => http.Response('unauthorized', 401));
      final languages = YouVersionLanguagesClient(
        appKey: 'invalid-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      try {
        await languages.listLanguages();
        fail('expected a YouVersionException');
      } on YouVersionException catch (e) {
        expect(e.reason, YouVersionErrorReason.missingAuthentication);
      }
    });
  });
}
