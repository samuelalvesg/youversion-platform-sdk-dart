import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform/youversion_platform.dart';

void main() {
  group('YouVersionDataExchangeClient', () {
    test('createToken envia Bearer do usuário e app-key na query, path com hífen', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/data-exchange/token');
        expect(request.url.queryParameters['app-key'], 'minha-app-key');
        expect(request.headers['Authorization'], 'Bearer access-1');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['requested_permissions'], ['highlights']);
        return http.Response(jsonEncode({'token': 'de-token-123'}), 201);
      });

      final client = YouVersionDataExchangeClient(
        appKey: 'minha-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final token = await client.createToken(userAccessToken: 'access-1');

      expect(token, 'de-token-123');
    });

    test('buildApprovalUrl usa path /data-exchange sem redirect_uri', () {
      final client = YouVersionDataExchangeClient(appKey: 'minha-app-key');

      final uri = client.buildApprovalUrl('de-token-123');

      expect(uri.path, '/data-exchange');
      expect(uri.queryParameters['token'], 'de-token-123');
      expect(uri.queryParameters['app_key'], 'minha-app-key');
      expect(uri.queryParameters['x-yvp-app-key'], 'minha-app-key');
      expect(uri.queryParameters.containsKey('redirect_uri'), isFalse);
    });
  });
}
