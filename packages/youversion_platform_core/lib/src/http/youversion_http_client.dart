import 'dart:convert';

import 'package:http/http.dart' as http;

import 'youversion_exception.dart';

/// Thin HTTP client shared by all modules (content, sign_in,
/// data_exchange, highlights, languages, organizations, votd). Holds no
/// authentication state - each call receives whatever headers it needs.
///
/// [timeout] prevents a call from hanging indefinitely (official SDKs
/// default to 10s, e.g. `ApiClient.request` in the React SDK).
class YouVersionHttpClient {
  YouVersionHttpClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  /// GETs [uri] without following redirects, returning the `Location`
  /// header of the resulting `3xx` response. Used by
  /// `YouVersionSignIn.resolveCallback` - see its doc comment.
  ///
  /// **Not supported on Flutter Web**: browsers make a manual-redirect
  /// fetch response opaque (no readable status/headers) for cross-origin
  /// requests, by design - this throws [YouVersionErrorReason.invalidResponse]
  /// there rather than silently returning nothing.
  Future<Uri> getRedirectLocation(Uri uri, {Map<String, String>? headers}) async {
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers.addAll(headers ?? const {});
    final streamedResponse = await _client.send(request).timeout(timeout);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 300 || response.statusCode >= 400) {
      throw YouVersionException(
        'Expected a redirect (3xx) response',
        statusCode: response.statusCode,
        body: response.body,
        reason: YouVersionErrorReason.invalidResponse,
      );
    }
    final location = response.headers['location'];
    if (location == null) {
      throw YouVersionException(
        'Redirect response has no Location header',
        statusCode: response.statusCode,
        reason: YouVersionErrorReason.invalidResponse,
      );
    }
    return Uri.parse(location);
  }

  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String>? headers,
    YouVersionErrorReason Function(int statusCode)? reasonForStatus,
  }) async {
    final response = await _client.get(uri, headers: headers).timeout(timeout);
    return _decode(response, reasonForStatus);
  }

  Future<Map<String, dynamic>> postForm(
    Uri uri, {
    required Map<String, String> body,
    Map<String, String>? headers,
    YouVersionErrorReason Function(int statusCode)? reasonForStatus,
  }) async {
    final response = await _client.post(uri, headers: headers, body: body).timeout(timeout);
    return _decode(response, reasonForStatus);
  }

  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    YouVersionErrorReason Function(int statusCode)? reasonForStatus,
  }) async {
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json', ...?headers},
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _decode(response, reasonForStatus);
  }

  Future<Map<String, dynamic>> putJson(
    Uri uri, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    YouVersionErrorReason Function(int statusCode)? reasonForStatus,
  }) async {
    final response = await _client
        .put(
          uri,
          headers: {'Content-Type': 'application/json', ...?headers},
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _decode(response, reasonForStatus);
  }

  /// DELETE tolerates an empty body on a `2xx` response (some endpoints,
  /// e.g. Highlights, respond without a body).
  Future<void> delete(
    Uri uri, {
    Map<String, String>? headers,
    YouVersionErrorReason Function(int statusCode)? reasonForStatus,
  }) async {
    final response = await _client.delete(uri, headers: headers).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFor(response, reasonForStatus);
    }
  }

  Map<String, dynamic> _decode(
    http.Response response,
    YouVersionErrorReason Function(int statusCode)? reasonForStatus,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFor(response, reasonForStatus);
    }
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw YouVersionException(
        'Unexpected response (not a JSON object)',
        statusCode: response.statusCode,
        body: response.body,
        reason: YouVersionErrorReason.invalidResponse,
      );
    }
    return decoded;
  }

  YouVersionException _errorFor(
    http.Response response,
    YouVersionErrorReason Function(int statusCode)? reasonForStatus,
  ) {
    final isRateLimited = response.statusCode == 429;
    return YouVersionException(
      'Request failed',
      statusCode: response.statusCode,
      body: response.body,
      reason: isRateLimited
          ? YouVersionErrorReason.rateLimited
          : reasonForStatus?.call(response.statusCode) ?? YouVersionErrorReason.cannotDownload,
      // Confirmed live: sent as a plain integer number of seconds (not an
      // HTTP-date, the header's other allowed form), e.g. `600` (10 min).
      retryAfter: isRateLimited ? _parseRetryAfter(response.headers['retry-after']) : null,
    );
  }

  Duration? _parseRetryAfter(String? headerValue) {
    final seconds = headerValue == null ? null : int.tryParse(headerValue);
    return seconds == null ? null : Duration(seconds: seconds);
  }

  void close() => _client.close();
}
