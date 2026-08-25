import 'dart:math';

import '../../http/youversion_exception.dart';
import '../../http/youversion_http_client.dart';
import '../../http/youversion_sdk_headers.dart';
import '../models/highlight.dart';

/// Highlights API (`/v1/highlights`) - direct CRUD over the authenticated
/// user's highlights, distinct from Data Exchange (which only creates a
/// one-off consent token). Requires the user's access token (obtained via
/// `YouVersionSignIn`) with the `highlights` permission granted.
///
/// Contract validated against platform-sdk-kotlin, `highlights/api/HighlightsEndpoints.kt`.
class YouVersionHighlightsClient {
  YouVersionHighlightsClient({
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

  Map<String, String> _headers(String userAccessToken) => {
        ...youVersionSdkHeaders(appKey: _appKey, installationId: _installationId),
        'Authorization': 'Bearer $userAccessToken',
      };

  YouVersionErrorReason _reasonForGet(int status) =>
      status == 401 ? YouVersionErrorReason.missingAuthentication : YouVersionErrorReason.cannotDownload;

  YouVersionErrorReason _reasonForWrite(int status) => switch (status) {
        401 => YouVersionErrorReason.missingAuthentication,
        403 => YouVersionErrorReason.notPermitted,
        _ => YouVersionErrorReason.cannotDownload,
      };

  /// Lists the user's highlights in a bible/passage. `204 No Content` =
  /// empty list (not an error).
  Future<List<Highlight>> listHighlights({
    required String userAccessToken,
    required int bibleId,
    String? passageId,
  }) async {
    final uri = _baseUri.replace(
      path: '/v1/highlights',
      queryParameters: {
        'bible_id': '$bibleId',
        if (passageId != null) 'passage_id': passageId,
      },
    );
    final json = await _http.getJson(
      uri,
      headers: _headers(userAccessToken),
      reasonForStatus: _reasonForGet,
    );
    final items = json['data'] as List<dynamic>? ?? const [];
    return items.map((item) => Highlight.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Creates a highlight. [color] must be a 6-character hex (with or
  /// without `#` - normalized internally) - see [HighlightColors].
  Future<Highlight> createHighlight({
    required String userAccessToken,
    required int bibleId,
    required String passageId,
    required String color,
  }) async {
    final json = await _http.postJson(
      _baseUri.replace(path: '/v1/highlights'),
      headers: _headers(userAccessToken),
      body: _highlightBody(bibleId: bibleId, passageId: passageId, color: color),
      reasonForStatus: _reasonForWrite,
    );
    return Highlight.fromJson(_unwrap(json));
  }

  /// Updates the color of an existing highlight (same body as create - the
  /// API identifies the highlight by `bible_id`+`passage_id`, not by `id`).
  Future<Highlight> updateHighlight({
    required String userAccessToken,
    required int bibleId,
    required String passageId,
    required String color,
  }) async {
    final json = await _http.putJson(
      _baseUri.replace(path: '/v1/highlights'),
      headers: _headers(userAccessToken),
      body: _highlightBody(bibleId: bibleId, passageId: passageId, color: color),
      reasonForStatus: _reasonForWrite,
    );
    return Highlight.fromJson(_unwrap(json));
  }

  /// Removes a highlight. `passageId` goes in the path (not a query param,
  /// unlike [listHighlights]) - asymmetry confirmed against the official
  /// SDK. Verse ranges (`MAT.1.1-MAT.1.5`) don't have confirmed support
  /// for removal - prefer single-verse ids.
  Future<void> deleteHighlight({
    required String userAccessToken,
    required int bibleId,
    required String passageId,
  }) async {
    final uri = _baseUri.replace(
      path: '/v1/highlights/$passageId',
      queryParameters: {'bible_id': '$bibleId'},
    );
    await _http.delete(
      uri,
      headers: _headers(userAccessToken),
      reasonForStatus: _reasonForWrite,
    );
  }

  Map<String, dynamic> _highlightBody({
    required int bibleId,
    required String passageId,
    required String color,
  }) {
    return {
      'request_id': _generateRequestId(),
      'highlight': {
        'bible_id': bibleId,
        'passage_id': passageId,
        'color': color.replaceFirst('#', '').toLowerCase(),
      },
    };
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    return data is Map<String, dynamic> ? data : json;
  }

  /// UUID v4 - used as an idempotency key in create/update (not idempotent
  /// across different retries, it only identifies the attempt).
  String _generateRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  void close() => _http.close();
}
