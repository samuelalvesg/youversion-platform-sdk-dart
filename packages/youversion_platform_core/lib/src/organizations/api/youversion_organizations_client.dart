import '../../http/youversion_exception.dart';
import '../../http/youversion_http_client.dart';
import '../../http/youversion_sdk_headers.dart';
import '../models/organization.dart';

/// Organizations API (`/v1/organizations`) - no OAuth, same App Key auth
/// as the Content API.
///
/// Contract validated against platform-sdk-kotlin, `organizations/api/OrganizationsEndpoints.kt`.
class YouVersionOrganizationsClient {
  YouVersionOrganizationsClient({
    required String appKey,
    String? installationId,
    Uri? baseUri,
    YouVersionHttpClient? httpClient,
  })  : _appKey = appKey,
        _installationId = installationId,
        _baseUri = baseUri ?? Uri.parse('https://api.youversion.com'),
        _http = httpClient ?? YouVersionHttpClient();

  final String _appKey;
  final String? _installationId;
  final Uri _baseUri;
  final YouVersionHttpClient _http;

  Map<String, String> get _headers => youVersionSdkHeaders(appKey: _appKey, installationId: _installationId);

  /// `401` = missing/invalid `X-YVP-App-Key` - confirmed live, same as
  /// `YouVersionContentClient._reasonForGet`.
  YouVersionErrorReason _reasonForGet(int status) =>
      status == 401 ? YouVersionErrorReason.missingAuthentication : YouVersionErrorReason.cannotDownload;

  /// Lists organizations associated with a bible (`Bible.id`).
  Future<List<Organization>> listOrganizations({int? bibleId}) async {
    final uri = _baseUri.replace(
      path: '/v1/organizations',
      queryParameters: {if (bibleId != null) 'bible_id': '$bibleId'},
    );
    final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
    final items = json['data'] as List<dynamic>? ?? const [];
    return items.map((item) => Organization.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Fetches an organization by id (`Bible.organizationId`).
  Future<Organization> getOrganization(String organizationId) async {
    final uri = _baseUri.replace(path: '/v1/organizations/$organizationId');
    final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
    final data = json['data'];
    return Organization.fromJson(data is Map<String, dynamic> ? data : json);
  }

  void close() => _http.close();
}
