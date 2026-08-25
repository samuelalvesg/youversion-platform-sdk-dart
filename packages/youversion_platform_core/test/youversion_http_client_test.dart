import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

void main() {
  group('YouVersionHttpClient', () {
    test('429 always maps to rateLimited, regardless of the caller\'s reasonForStatus', () async {
      final mockClient = MockClient((request) async => http.Response('too many requests', 429));
      final client = YouVersionHttpClient(client: mockClient);

      try {
        // A reasonForStatus that would otherwise map every non-2xx status
        // to something else - 429 must still win.
        await client.getJson(
          Uri.parse('https://api.youversion.com/v1/bibles'),
          reasonForStatus: (_) => YouVersionErrorReason.cannotDownload,
        );
        fail('expected a YouVersionException');
      } on YouVersionException catch (e) {
        expect(e.reason, YouVersionErrorReason.rateLimited);
        expect(e.statusCode, 429);
      }
    });

    test('429 parses Retry-After (seconds) into retryAfter - confirmed live, "retry-after: 600"', () async {
      final mockClient = MockClient(
        (request) async => http.Response('too many requests', 429, headers: {'retry-after': '600'}),
      );
      final client = YouVersionHttpClient(client: mockClient);

      try {
        await client.getJson(Uri.parse('https://api.youversion.com/v1/bibles'));
        fail('expected a YouVersionException');
      } on YouVersionException catch (e) {
        expect(e.retryAfter, const Duration(seconds: 600));
      }
    });

    test('429 without a Retry-After header leaves retryAfter null', () async {
      final mockClient = MockClient((request) async => http.Response('too many requests', 429));
      final client = YouVersionHttpClient(client: mockClient);

      try {
        await client.getJson(Uri.parse('https://api.youversion.com/v1/bibles'));
        fail('expected a YouVersionException');
      } on YouVersionException catch (e) {
        expect(e.retryAfter, isNull);
      }
    });

    test('a non-429 status still uses the caller-supplied reasonForStatus', () async {
      final mockClient = MockClient((request) async => http.Response('forbidden', 403));
      final client = YouVersionHttpClient(client: mockClient);

      try {
        await client.getJson(
          Uri.parse('https://api.youversion.com/v1/bibles'),
          reasonForStatus: (status) =>
              status == 403 ? YouVersionErrorReason.notPermitted : YouVersionErrorReason.cannotDownload,
        );
        fail('expected a YouVersionException');
      } on YouVersionException catch (e) {
        expect(e.reason, YouVersionErrorReason.notPermitted);
      }
    });
  });
}
