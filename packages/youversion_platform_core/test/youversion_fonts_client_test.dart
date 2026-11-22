import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

YouVersionFontsClient _client(
    http.Response Function(http.Request request) respond) {
  return YouVersionFontsClient(
    appKey: 'my-app-key',
    httpClient: YouVersionHttpClient(
        client: MockClient((request) async => respond(request))),
  );
}

Map<String, Object> _fontJson({String host = 'cdn.youversion.com', int weight = 400}) => {
      'id': 1,
      'slug': 'untitled-serif',
      'family': 'Untitled Serif',
      'variants': [
        {
          'weight': weight,
          'style': 'normal',
          'sources': [
            {'format': 'woff2', 'url': 'https://$host/fonts/serif-400.woff2'}
          ],
        }
      ],
    };

void main() {
  test('getFont calls /v1/fonts/{id} with the app key and decodes the variants', () async {
    late http.Request seen;
    final client = _client((request) {
      seen = request;
      return http.Response(jsonEncode(_fontJson()), 200);
    });

    final font = await client.getFont(1);

    expect(seen.url.path, '/v1/fonts/1');
    expect(seen.headers['X-YVP-App-Key'], 'my-app-key');
    expect(font.family, 'Untitled Serif');
    expect(font.variants.single.sources.single.format, 'woff2');
  });

  test('a font file from a host outside the allow-list is rejected', () async {
    final client = _client((_) => http.Response(jsonEncode(_fontJson(host: 'evil.example')), 200));
    await expectLater(client.getFont(1), throwsA(isA<FormatException>()));
  });

  test('unsupported weights are rejected', () async {
    final client = _client((_) => http.Response(jsonEncode(_fontJson(weight: 300)), 200));
    await expectLater(client.getFont(1), throwsA(isA<FormatException>()));
  });

  test('an unknown font id maps to notPermitted', () async {
    final client = _client((_) => http.Response('{}', 404));
    await expectLater(
      client.getFont(999),
      throwsA(isA<YouVersionException>()
          .having((e) => e.reason, 'reason', YouVersionErrorReason.notPermitted)),
    );
  });
}
