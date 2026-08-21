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
    final response =
        await _client.post(uri, headers: headers, body: body).timeout(timeout);
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
    return YouVersionException(
      'Request failed',
      statusCode: response.statusCode,
      body: response.body,
      reason: reasonForStatus?.call(response.statusCode) ??
          YouVersionErrorReason.cannotDownload,
    );
  }

  void close() => _client.close();
}
