import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform/youversion_platform.dart';

String _fakeIdToken(Map<String, dynamic> claims) {
  final header = base64Url.encode(utf8.encode('{"alg":"none"}')).replaceAll('=', '');
  final payload = base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');
  return '$header.$payload.sig';
}

void main() {
  group('YouVersionSignIn', () {
    test('buildAuthorizationUrl monta a URL com PKCE, scope e permissões opcionais', () {
      final signIn = YouVersionSignIn(
        appKey: 'minha-app-key',
        redirectUri: Uri.parse('https://app.example.com/auth/callback'),
      );

      final request = signIn.buildAuthorizationUrl(
        permissions: {
          YouVersionPermission.profile,
          YouVersionPermission.email,
          YouVersionPermission.highlights,
        },
      );

      final uri = request.authorizationUrl;
      expect(uri.path, '/auth/authorize');
      expect(uri.queryParameters['client_id'], 'minha-app-key');
      expect(uri.queryParameters['code_challenge_method'], 'S256');
      expect(uri.queryParameters['scope'], 'email openid profile');
      expect(uri.queryParameters['requested_permissions'], 'highlights');
      expect(uri.queryParameters['require_user_interaction'], 'true');
      expect(request.codeVerifier, isNotEmpty);
      expect(request.state, isNotEmpty);
      expect(request.nonce, isNotEmpty);
    });

    test('exchangeCode troca o code por tokens e valida state/nonce', () async {
      final idToken = _fakeIdToken({'sub': 'user-1', 'nonce': 'nonce-abc'});

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/auth/token');
        final body = Uri.splitQueryString(request.body);
        expect(body['grant_type'], 'authorization_code');
        expect(body['code'], 'code-123');
        expect(body['code_verifier'], 'verifier-abc');
        return http.Response(
          jsonEncode({
            'access_token': 'access-1',
            'refresh_token': 'refresh-1',
            'expires_in': 3600,
            'scope': 'openid profile email',
            'id_token': idToken,
          }),
          200,
        );
      });

      final signIn = YouVersionSignIn(
        appKey: 'minha-app-key',
        redirectUri: Uri.parse('https://app.example.com/auth/callback'),
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final token = await signIn.exchangeCode(
        code: 'code-123',
        codeVerifier: 'verifier-abc',
        receivedState: 'state-abc',
        expectedState: 'state-abc',
        expectedNonce: 'nonce-abc',
      );

      expect(token.accessToken, 'access-1');
      expect(token.idToken, isNotNull);
    });

    test('exchangeCode rejeita state divergente', () async {
      final signIn = YouVersionSignIn(
        appKey: 'minha-app-key',
        redirectUri: Uri.parse('https://app.example.com/auth/callback'),
      );

      expect(
        () => signIn.exchangeCode(
          code: 'code-123',
          codeVerifier: 'verifier-abc',
          receivedState: 'outro-state',
          expectedState: 'state-abc',
        ),
        throwsA(isA<YouVersionException>()),
      );
    });

    test('decodeIdentity lê os claims do id_token (picture, não profile_picture)', () {
      final signIn = YouVersionSignIn(
        appKey: 'minha-app-key',
        redirectUri: Uri.parse('https://app.example.com/auth/callback'),
      );

      final idToken = _fakeIdToken({
        'sub': 'user-1',
        'yvp_id': 'user-1',
        'email': 'user@example.com',
        'name': 'Fulano',
        'picture': 'https://example.com/foto.jpg',
      });

      final identity = signIn.decodeIdentity(idToken);

      expect(identity.sub, 'user-1');
      expect(identity.email, 'user@example.com');
      expect(identity.profilePicture, 'https://example.com/foto.jpg');
    });

    test('refreshToken não exige id_token na resposta', () async {
      final mockClient = MockClient((request) async {
        final body = Uri.splitQueryString(request.body);
        expect(body['grant_type'], 'refresh_token');
        return http.Response(
          jsonEncode({
            'access_token': 'access-2',
            'refresh_token': 'refresh-2',
            'expires_in': 3600,
            'scope': 'openid profile email',
          }),
          200,
        );
      });

      final signIn = YouVersionSignIn(
        appKey: 'minha-app-key',
        redirectUri: Uri.parse('https://app.example.com/auth/callback'),
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final token = await signIn.refreshToken('refresh-1');

      expect(token.accessToken, 'access-2');
      expect(token.idToken, isNull);
    });
  });
}
