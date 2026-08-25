import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

void main() {
  group('YouVersionSignIn.resolveCallback', () {
    test('follows /auth/callback and returns the Location header as a Uri', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/auth/callback');
        expect(request.url.queryParameters['state'], 'abc');
        expect(request.url.queryParameters['granted_permissions'], 'highlights');
        return http.Response(
          '',
          302,
          headers: {
            'location': 'https://example.com/callback?code=ObBAnhlk&state=abc',
          },
        );
      });
      final signIn = YouVersionSignIn(
        appKey: 'k',
        redirectUri: Uri.parse('https://example.com/callback'),
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final resolved = await signIn.resolveCallback(
        Uri.parse('https://example.com/callback?state=abc&granted_permissions=highlights'),
      );

      expect(resolved.queryParameters['code'], 'ObBAnhlk');
      expect(resolved.queryParameters['state'], 'abc');
    });

    test('throws invalidResponse when the response has no Location header', () async {
      final mockClient = MockClient((request) async => http.Response('', 302));
      final signIn = YouVersionSignIn(
        appKey: 'k',
        redirectUri: Uri.parse('https://example.com/callback'),
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      try {
        await signIn.resolveCallback(Uri.parse('https://example.com/callback?state=abc'));
        fail('expected a YouVersionException');
      } on YouVersionException catch (e) {
        expect(e.reason, YouVersionErrorReason.invalidResponse);
      }
    });

    test('throws invalidResponse when the response is not a redirect', () async {
      final mockClient = MockClient((request) async => http.Response('ok', 200));
      final signIn = YouVersionSignIn(
        appKey: 'k',
        redirectUri: Uri.parse('https://example.com/callback'),
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      try {
        await signIn.resolveCallback(Uri.parse('https://example.com/callback?state=abc'));
        fail('expected a YouVersionException');
      } on YouVersionException catch (e) {
        expect(e.reason, YouVersionErrorReason.invalidResponse);
      }
    });
  });
}
