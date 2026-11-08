import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

void main() {
  group('YouVersionVotdClient', () {
    test('listAll decodes the full list', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/verse-of-the-days');
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
        expect(request.url.path, '/v1/verse-of-the-days/42');
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

    test('getDay sends language_ranges[] and decodes image_id', () async {
      late Uri seen;
      final votd = YouVersionVotdClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(
          client: MockClient((request) async {
            seen = request.url;
            return http.Response(
                jsonEncode({
                  'day': 1,
                  'passage_id': 'ISA.43.18-19',
                  'image_id': 'abc'
                }),
                200);
          }),
        ),
      );

      final day = await votd.getDay(1, languageRanges: ['es', 'en']);

      expect(seen.queryParametersAll['language_ranges[]'], ['es', 'en']);
      expect(day.imageId, 'abc');
    });

    test('without language_ranges there is no query string and imageId is null',
        () async {
      late Uri seen;
      final votd = YouVersionVotdClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(
          client: MockClient((request) async {
            seen = request.url;
            return http.Response(
                jsonEncode(
                    {'day': 1, 'passage_id': 'ISA.43.18-19', 'image_id': null}),
                200);
          }),
        ),
      );

      final day = await votd.getDay(1);

      expect(seen.hasQuery, isFalse);
      expect(day.imageId, isNull);
    });

    test('listAll passes language_ranges[] and reads image ids from data',
        () async {
      late Uri seen;
      final votd = YouVersionVotdClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(
          client: MockClient((request) async {
            seen = request.url;
            return http.Response(
              jsonEncode({
                'data': [
                  {'day': 1, 'passage_id': 'ISA.43.19', 'image_id': 'x'},
                ],
              }),
              200,
            );
          }),
        ),
      );

      final all = await votd.listAll(languageRanges: ['en']);

      expect(seen.path, '/v1/verse-of-the-days');
      expect(all.single.imageId, 'x');
    });
  });
}
