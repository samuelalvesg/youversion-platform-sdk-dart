import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform/youversion_platform.dart';

void main() {
  group('YouVersionContentClient', () {
    test('listBibles envia X-YVP-App-Key e decodifica a lista', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-YVP-App-Key'], 'minha-app-key');
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
          }),
          200,
        );
      });

      final content = YouVersionContentClient(
        appKey: 'minha-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final bibles = await content.listBibles(languageRanges: ['en']);

      expect(bibles, hasLength(1));
      expect(bibles.first.id, 111);
      expect(bibles.first.title, 'New International Version');
    });

    test('listBibles sem idiomas usa language_ranges[]=*', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['language_ranges[]'], '*');
        return http.Response(jsonEncode({'data': <dynamic>[]}), 200);
      });

      final content = YouVersionContentClient(
        appKey: 'minha-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      await content.listBibles();
    });

    test('getPassage decodifica o conteúdo do trecho (envelope data)', () async {
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
        appKey: 'minha-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final passage = await content.getPassage(
        bibleId: 111,
        passageId: 'JHN.3.16',
      );

      expect(passage.reference, 'John 3:16');
    });

    test('erro HTTP lança YouVersionException', () async {
      final mockClient = MockClient((request) async {
        return http.Response('não autorizado', 401);
      });

      final content = YouVersionContentClient(
        appKey: 'invalida',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      expect(
        () => content.listBibles(languageRanges: ['en']),
        throwsA(isA<YouVersionException>()),
      );
    });
  });
}
