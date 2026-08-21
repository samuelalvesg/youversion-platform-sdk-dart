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
  });
}
