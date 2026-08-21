import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

String _fakeIdToken(Map<String, dynamic> claims) {
  final header = base64Url.encode(utf8.encode('{"alg":"none"}')).replaceAll('=', '');
  final payload = base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');
  return '$header.$payload.sig';
}

void main() {
  group('YouVersionSignIn', () {
    test('buildAuthorizationUrl builds the URL with PKCE, scope and optional permissions', () {
      final signIn = YouVersionSignIn(
        appKey: 'my-app-key',
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
      expect(uri.queryParameters['client_id'], 'my-app-key');
      expect(uri.queryParameters['code_challenge_method'], 'S256');
      expect(uri.queryParameters['scope'], 'email openid profile');
      expect(uri.queryParameters['requested_permissions'], 'highlights');
      expect(uri.queryParameters['require_user_interaction'], 'true');
      expect(request.codeVerifier, isNotEmpty);
      expect(request.state, isNotEmpty);
      expect(request.nonce, isNotEmpty);
    });

    test('exchangeCode exchanges the code for tokens and validates state/nonce', () async {
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
        appKey: 'my-app-key',
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

    test('exchangeCode rejects a mismatched state', () async {
      final signIn = YouVersionSignIn(
        appKey: 'my-app-key',
        redirectUri: Uri.parse('https://app.example.com/auth/callback'),
      );

      expect(
        () => signIn.exchangeCode(
          code: 'code-123',
          codeVerifier: 'verifier-abc',
          receivedState: 'different-state',
          expectedState: 'state-abc',
        ),
        throwsA(isA<YouVersionException>()),
      );
    });

    test('decodeIdentity reads the id_token claims (picture, not profile_picture)', () {
      final signIn = YouVersionSignIn(
        appKey: 'my-app-key',
        redirectUri: Uri.parse('https://app.example.com/auth/callback'),
      );

      final idToken = _fakeIdToken({
        'sub': 'user-1',
        'yvp_id': 'user-1',
        'email': 'user@example.com',
        'name': 'John Doe',
        'picture': 'https://example.com/photo.jpg',
      });

      final identity = signIn.decodeIdentity(idToken);

      expect(identity.sub, 'user-1');
      expect(identity.email, 'user@example.com');
      expect(identity.profilePicture, 'https://example.com/photo.jpg');
    });

    test('refreshToken does not require id_token in the response', () async {
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
        appKey: 'my-app-key',
        redirectUri: Uri.parse('https://app.example.com/auth/callback'),
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final token = await signIn.refreshToken('refresh-1');

      expect(token.accessToken, 'access-2');
      expect(token.idToken, isNull);
    });
  });
}
