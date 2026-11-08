import '../../http/youversion_exception.dart';
import '../../http/youversion_http_client.dart';
import '../../http/youversion_sdk_headers.dart';
import '../models/verse_image.dart';

/// Images API (`/v1/images`, `/v1/images/{id}`, `/v1/search-images`) - App Key
/// auth only, no sign-in. Contract from developers.youversion.com/guides/images.
///
/// Responses are `Cache-Control: private` and image ids are minted per
/// response: cache per user/session with a key that includes the request
/// parameters, never share them, and do not store ids.
class YouVersionImagesClient {
  YouVersionImagesClient({
    required String appKey,
    String? installationId,
    Uri? baseUri,
    YouVersionHttpClient? httpClient,
  })  : _appKey = appKey,
        _installationId = installationId,
        _baseUri = baseUri ?? Uri.parse('https://api.youversion.com'),
        _http = httpClient ?? YouVersionHttpClient();

  static const maxQueryLength = 100;
  static const maxPageSize = 99;

  final String _appKey;
  final String? _installationId;
  final Uri _baseUri;
  final YouVersionHttpClient _http;

  Map<String, String> get _headers =>
      youVersionSdkHeaders(appKey: _appKey, installationId: _installationId);

  YouVersionErrorReason _reason(int status) => switch (status) {
        401 => YouVersionErrorReason.missingAuthentication,
        404 => YouVersionErrorReason.notPermitted,
        _ => YouVersionErrorReason.cannotDownload,
      };

  void _checkPageSize(int? pageSize) {
    if (pageSize != null && (pageSize < 1 || pageSize > maxPageSize)) {
      throw ArgumentError.value(pageSize, 'pageSize', 'must be 1-$maxPageSize');
    }
  }

  /// Resolves an image [id] exactly as another endpoint returned it. A
  /// malformed or unknown id answers `404`.
  Future<VerseImage> getImage(String id) async {
    final uri = _baseUri.replace(pathSegments: ['v1', 'images', id]);
    final json =
        await _http.getJson(uri, headers: _headers, reasonForStatus: _reason);
    return VerseImage.fromJson(json);
  }

  /// Full image records, optionally for one [passageId] (a verse or verse
  /// range; chapter ids such as `JHN.3` are not supported) and/or art
  /// language. Regional tags such as `es-MX` have no art here: send `es`.
  /// No match is an empty page (the API answers `204`).
  Future<VerseImagePage> listImages({
    String? passageId,
    List<String>? languageRanges,
    int? pageSize,
    String? pageToken,
  }) async {
    _checkPageSize(pageSize);
    final uri = _baseUri.replace(
      path: '/v1/images',
      queryParameters: {
        if (passageId != null) 'passage_id': [passageId],
        if (languageRanges != null && languageRanges.isNotEmpty)
          'language_ranges[]': languageRanges,
        if (pageSize != null) 'page_size': ['$pageSize'],
        if (pageToken != null) 'page_token': [pageToken],
      },
    );
    final json =
        await _http.getJson(uri, headers: _headers, reasonForStatus: _reason);
    return json.isEmpty
        ? const VerseImagePage.empty()
        : VerseImagePage.fromJson(json);
  }

  /// Image references matching [query]; the Bible [bibleId] decides the
  /// language searched. Send the same arguments with each [pageToken]. No
  /// match is an empty page (`204`).
  Future<ImageSearchPage> searchImages({
    required String query,
    required int bibleId,
    int? pageSize,
    String? pageToken,
  }) async {
    if (query.isEmpty || query.length > maxQueryLength) {
      throw ArgumentError.value(
          query, 'query', 'must be 1-$maxQueryLength characters');
    }
    _checkPageSize(pageSize);
    final uri = _baseUri.replace(
      path: '/v1/search-images',
      queryParameters: {
        'query': [query],
        'bible_id': ['$bibleId'],
        if (pageSize != null) 'page_size': ['$pageSize'],
        if (pageToken != null) 'page_token': [pageToken],
      },
    );
    final json =
        await _http.getJson(uri, headers: _headers, reasonForStatus: _reason);
    return json.isEmpty
        ? const ImageSearchPage.empty()
        : ImageSearchPage.fromJson(json);
  }

  void close() => _http.close();
}
