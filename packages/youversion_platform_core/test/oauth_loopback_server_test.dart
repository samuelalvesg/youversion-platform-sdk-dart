import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

void main() {
  group('OAuthLoopbackServer', () {
    test('redirectUri matches the port/path it was started with', () async {
      final server = await OAuthLoopbackServer.start(port: 51739, path: '/callback');
      addTearDown(server.dispose);

      expect(server.redirectUri, Uri.parse('http://127.0.0.1:51739/callback'));
    });

    test('waitForCallback returns the redirect query parameters, then closes the server', () async {
      final server = await OAuthLoopbackServer.start(port: 51740, path: '/callback');

      final callback = server.waitForCallback(timeout: const Duration(seconds: 5));
      await http.get(Uri.parse('http://127.0.0.1:51740/callback?code=abc123&state=xyz'));
      final result = await callback;

      expect(result.queryParameters['code'], 'abc123');
      expect(result.queryParameters['state'], 'xyz');

      // The server closed itself after the single request - a second one
      // should fail to connect, not hang waiting.
      await expectLater(
        http.get(Uri.parse('http://127.0.0.1:51740/callback')),
        throwsA(isA<SocketException>()),
      );
    });

    test(
        'waitForCallback ignores requests to other paths (e.g. a stray /favicon.ico) '
        'instead of answering the wrong one and closing early', () async {
      final server = await OAuthLoopbackServer.start(port: 51742, path: '/callback');

      final callback = server.waitForCallback(timeout: const Duration(seconds: 5));
      // Confirmed live: unlike a callback redirect from a backend the app
      // controls itself (one clean request), a real third-party OAuth/
      // login page's browser can hit this origin with something else
      // first (favicon, a CORS preflight) before the actual navigation -
      // the server must not treat that as *the* callback.
      final strayResponse = await http.get(Uri.parse('http://127.0.0.1:51742/favicon.ico'));
      expect(strayResponse.statusCode, 404);

      final realResponse = await http.get(Uri.parse('http://127.0.0.1:51742/callback?code=abc123&state=xyz'));
      expect(realResponse.statusCode, 200);

      final result = await callback;
      expect(result.queryParameters['code'], 'abc123');
      expect(result.queryParameters['state'], 'xyz');
    });

    test('waitForCallback times out (and still closes the server) if nothing arrives', () async {
      final server = await OAuthLoopbackServer.start(port: 51741, path: '/callback');

      await expectLater(
        server.waitForCallback(timeout: const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
