import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

void main() {
  group('YouVersionVotdClient', () {
    test('listAll decodes the full list', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/verse_of_the_days');
        return http.Response(
          jsonEncode({
            'data': [
              {'day': 1, 'passage_id': 'ISA.43.19'},
            ],
          }),
          200,
        );
      });

      final votd = YouVersionVotdClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final result = await votd.listAll();

      expect(result.first.day, 1);
      expect(result.first.passageId, 'ISA.43.19');
    });

    test('getDay returns a direct object without a list envelope', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/verse_of_the_days/42');
        return http.Response(
          jsonEncode({'day': 42, 'passage_id': 'JHN.3.16'}),
          200,
        );
      });

      final votd = YouVersionVotdClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final day = await votd.getDay(42);

      expect(day.passageId, 'JHN.3.16');
    });
  });
}
