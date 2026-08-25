import '../../http/youversion_http_client.dart';
import '../../http/youversion_sdk_headers.dart';
import '../models/verse_of_the_day.dart';

/// VOTD (Verse of the Day) API (`/v1/verse_of_the_days`) - no OAuth, same
/// App Key auth as the Content API.
///
/// Contract validated against platform-sdk-kotlin, `votd/api/VotdEndpoints.kt`.
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

  Map<String, String> get _headers => youVersionSdkHeaders(appKey: _appKey, installationId: _installationId);

  /// Lists all verses of the day for the year.
  Future<List<VerseOfTheDay>> listAll() async {
    final uri = _baseUri.replace(path: '/v1/verse_of_the_days');
    final json = await _http.getJson(uri, headers: _headers);
    final items = json['data'] as List<dynamic>? ?? const [];
    return items.map((item) => VerseOfTheDay.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Fetches the verse for a specific day of the year (1-366). The response
  /// comes as a direct object, without a list envelope.
  Future<VerseOfTheDay> getDay(int dayOfYear) async {
    final uri = _baseUri.replace(path: '/v1/verse_of_the_days/$dayOfYear');
    final json = await _http.getJson(uri, headers: _headers);
    final data = json['data'];
    return VerseOfTheDay.fromJson(data is Map<String, dynamic> ? data : json);
  }

  void close() => _http.close();
}
