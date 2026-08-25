import '../../content/models/collection.dart';
import '../../http/youversion_exception.dart';
import '../../http/youversion_http_client.dart';
import '../../http/youversion_sdk_headers.dart';
import '../models/language.dart';

/// Languages API (`/v1/languages`).
///
/// Contract validated against platform-sdk-kotlin, `languages/api/LanguagesEndpoints.kt`.
class YouVersionLanguagesClient {
  YouVersionLanguagesClient({
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

  /// Lists supported languages. [country] filters by country (ISO 3166-1
  /// alpha-2). [fields] requests a sparse fieldset (1-3 fields forces
  /// `page_size=*`, same as in [YouVersionContentClient.listBibles]).
  Future<YouVersionCollection<Language>> listLanguages({
    String? country,
    List<String>? fields,
    int? pageSize,
    String? pageToken,
  }) async {
    final uri = _baseUri.replace(
      path: '/v1/languages',
      queryParameters: {
        if (country != null) 'country': country,
        if (fields != null) 'fields[]': fields,
        if (pageSize != null) 'page_size': '$pageSize',
        if (pageToken != null) 'page_token': pageToken,
      },
    );
    final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
    return YouVersionCollection.fromJson(json, Language.fromJson);
  }

  /// Fetches a language by id.
  Future<Language> getLanguage(String languageId) async {
    final uri = _baseUri.replace(path: '/v1/languages/$languageId');
    final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
    final data = json['data'];
    return Language.fromJson(data is Map<String, dynamic> ? data : json);
  }

  void close() => _http.close();
}
