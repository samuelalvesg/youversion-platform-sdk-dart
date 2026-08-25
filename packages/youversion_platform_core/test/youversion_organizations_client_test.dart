import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

void main() {
  group('YouVersionOrganizationsClient', () {
    test('listOrganizations filters by bible_id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/organizations');
        expect(request.url.queryParameters['bible_id'], '111');
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 'org-1', 'name': 'Publisher Inc.'},
            ],
          }),
          200,
        );
      });

      final organizations = YouVersionOrganizationsClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final result = await organizations.listOrganizations(bibleId: 111);

      expect(result, hasLength(1));
      expect(result.first.name, 'Publisher Inc.');
    });

    test('getOrganization fetches a single item', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/organizations/org-1');
        return http.Response(
          jsonEncode({
            'data': {'id': 'org-1', 'name': 'Publisher Inc.'},
          }),
          200,
        );
      });

      final organizations = YouVersionOrganizationsClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final organization = await organizations.getOrganization('org-1');

      expect(organization.name, 'Publisher Inc.');
    });

    test('listOrganizations decodes a structured "address" - confirmed live, not a plain string', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'org-1',
                'name': 'Publisher Inc.',
                'address': {
                  'formatted_address': '7255 W. Camp Wisdom Rd., Dallas, TX 75236',
                  'formatted_locality': 'US',
                  'place_id': '',
                  'latitude': 32.66666,
                  'longitude': -96.95123,
                  'administrative_area_level_1': {'short_name': '', 'long_name': ''},
                  'locality': {'short_name': '', 'long_name': ''},
                  'country': {'short_name': 'US', 'long_name': 'US'},
                },
              },
            ],
          }),
          200,
        );
      });

      final organizations = YouVersionOrganizationsClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final result = await organizations.listOrganizations();

      final address = result.first.address;
      expect(address, isNotNull);
      expect(address!.formattedAddress, '7255 W. Camp Wisdom Rd., Dallas, TX 75236');
      expect(address.country?.shortName, 'US');
    });

    test('listOrganizations tolerates a null "address"', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 'org-1', 'name': 'Publisher Inc.', 'address': null},
            ],
          }),
          200,
        );
      });

      final organizations = YouVersionOrganizationsClient(
        appKey: 'my-app-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      final result = await organizations.listOrganizations();

      expect(result.first.address, isNull);
    });

    test('401 (missing/invalid App Key) maps to missingAuthentication', () async {
      final mockClient = MockClient((request) async => http.Response('unauthorized', 401));
      final organizations = YouVersionOrganizationsClient(
        appKey: 'invalid-key',
        httpClient: YouVersionHttpClient(client: mockClient),
      );

      try {
        await organizations.listOrganizations();
        fail('expected a YouVersionException');
      } on YouVersionException catch (e) {
        expect(e.reason, YouVersionErrorReason.missingAuthentication);
      }
    });
  });
}
