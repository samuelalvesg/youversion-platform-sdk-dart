import '../../http/youversion_http_client.dart';
import '../../http/youversion_sdk_headers.dart';
import '../models/verse_of_the_day.dart';

/// VOTD (Verse of the Day) API (`/v1/verse-of-the-days`) - no OAuth, same
/// App Key auth as the Content API. Path per developers.youversion.com
/// (guides/images); the older underscore spelling is no longer used.
class YouVersionVotdClient {
  YouVersionVotdClient({
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

  Map<String, String> get _headers =>
      youVersionSdkHeaders(appKey: _appKey, installationId: _installationId);

  Uri _uri(String path, List<String>? languageRanges) => _baseUri.replace(
        path: path,
        queryParameters: languageRanges == null || languageRanges.isEmpty
            ? null
            : {'language_ranges[]': languageRanges},
      );

  /// Lists all verses of the day for the year. With [languageRanges] each
  /// item may carry an `imageId` (resolve it with `YouVersionImagesClient`).
  Future<List<VerseOfTheDay>> listAll({List<String>? languageRanges}) async {
    final uri = _uri('/v1/verse-of-the-days', languageRanges);
    final json = await _http.getJson(uri, headers: _headers);
    final items = json['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) => VerseOfTheDay.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the verse for a specific day of the year (1-366). The response
  /// comes as a direct object, without a list envelope. [languageRanges]
  /// selects the art language; without it `imageId` is always null.
  Future<VerseOfTheDay> getDay(int dayOfYear,
      {List<String>? languageRanges}) async {
    final uri = _uri('/v1/verse-of-the-days/$dayOfYear', languageRanges);
    final json = await _http.getJson(uri, headers: _headers);
    final data = json['data'];
    return VerseOfTheDay.fromJson(data is Map<String, dynamic> ? data : json);
  }

  void close() => _http.close();
}
