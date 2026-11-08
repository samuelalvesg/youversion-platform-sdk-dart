import '../../http/youversion_exception.dart';
import '../../http/youversion_http_client.dart';
import '../../http/youversion_sdk_headers.dart';
import '../models/search_models.dart';

/// Search API (`/v1/search-unified`, `/v1/search-verses`,
/// `/v1/search-topics`, `/v1/search-queries`) - App Key auth only, no OAuth.
///
/// Contract taken from developers.youversion.com/search-apis. Verse hits are
/// USFM references without text: resolve them with the Content client's
/// passage calls (mind the request budget when resolving many).
class YouVersionSearchClient {
  YouVersionSearchClient({
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

  /// `404` on verse search means "this Bible is not available to the app"
  /// (unlicensed or not live), not "unknown id".
  YouVersionErrorReason _reasonForSearch(int status) => switch (status) {
        401 => YouVersionErrorReason.missingAuthentication,
        404 => YouVersionErrorReason.notPermitted,
        _ => YouVersionErrorReason.cannotDownload,
      };

  void _checkQuery(String query) {
    if (query.isEmpty || query.length > maxQueryLength) {
      throw ArgumentError.value(
          query, 'query', 'must be 1-$maxQueryLength characters');
    }
  }

  Future<Map<String, dynamic>> _get(
      String path, Map<String, List<String>> params) {
    final uri = _baseUri.replace(path: path, queryParameters: params);
    return _http.getJson(uri,
        headers: _headers, reasonForStatus: _reasonForSearch);
  }

  /// Top verses and topics for [query] in one call (unpaginated). [bibleId]
  /// must be a Bible the app is licensed for. [languageRanges] (BCP 47, `*`
  /// for all) select the topic language. [fields] limits the result kinds.
  Future<UnifiedSearchResult> searchUnified({
    required String query,
    required int bibleId,
    required List<String> languageRanges,
    SearchUserIntent? userIntent,
    List<SearchField>? fields,
  }) async {
    _checkQuery(query);
    final json = await _get('/v1/search-unified', {
      'query': [query],
      'bible_id': ['$bibleId'],
      'language_ranges[]': languageRanges,
      if (userIntent != null) 'user_intent': [userIntent.name],
      if (fields != null) 'fields[]': [for (final field in fields) field.name],
    });
    return UnifiedSearchResult.fromJson(json);
  }

  /// One page of matching verses; pass [VerseSearchPage.nextPageToken] as
  /// [pageToken] for the next one. [pageSize] is 1-$maxPageSize (API default 25).
  Future<VerseSearchPage> searchVerses({
    required String query,
    required int bibleId,
    SearchUserIntent? userIntent,
    int? pageSize,
    String? pageToken,
  }) async {
    _checkQuery(query);
    if (pageSize != null && (pageSize < 1 || pageSize > maxPageSize)) {
      throw ArgumentError.value(pageSize, 'pageSize', 'must be 1-$maxPageSize');
    }
    final json = await _get('/v1/search-verses', {
      'query': [query],
      'bible_id': ['$bibleId'],
      if (userIntent != null) 'user_intent': [userIntent.name],
      if (pageSize != null) 'page_size': ['$pageSize'],
      if (pageToken != null) 'page_token': [pageToken],
    });
    return VerseSearchPage.fromJson(json);
  }

  /// Every topic related to [query] (unpaginated). A topic's `text` can be
  /// used as the query of [searchVerses] to pivot to its verses.
  Future<TopicSearchResult> searchTopics(
      {required String query, required List<String> languageRanges}) async {
    _checkQuery(query);
    final json = await _get('/v1/search-topics', {
      'query': [query],
      'language_ranges[]': languageRanges,
    });
    return TopicSearchResult.fromJson(json);
  }

  /// As-you-type suggestions for the partial [query]. Empty list when the
  /// service has none (it answers `204`).
  Future<List<SearchQuerySuggestion>> suggestQueries({
    required String query,
    required List<String> languageRanges,
  }) async {
    _checkQuery(query);
    return _queries({
      'query': [query],
      'language_ranges[]': languageRanges
    });
  }

  /// Recently popular searches. Empty list when there are none (`204`).
  Future<List<SearchQuerySuggestion>> trendingQueries(
      {required List<String> languageRanges}) {
    return _queries({
      'trending': ['true'],
      'language_ranges[]': languageRanges
    });
  }

  Future<List<SearchQuerySuggestion>> _queries(
      Map<String, List<String>> params) async {
    final json = await _get('/v1/search-queries', params);
    final items = json['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) =>
            SearchQuerySuggestion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  void close() => _http.close();
}
