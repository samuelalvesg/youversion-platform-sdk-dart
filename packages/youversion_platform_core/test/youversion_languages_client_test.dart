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
