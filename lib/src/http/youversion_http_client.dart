import 'dart:convert';

import 'package:http/http.dart' as http;

import 'youversion_exception.dart';

/// Cliente HTTP fino compartilhado pelos módulos content/sign_in/data_exchange.
/// Não guarda estado de autenticação - cada chamada recebe os headers que precisa.
class YouVersionHttpClient {
  YouVersionHttpClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final response = await _client.get(uri, headers: headers);
    return _decode(response);
  }

  Future<Map<String, dynamic>> postForm(
    Uri uri, {
    required Map<String, String> body,
    Map<String, String>? headers,
  }) async {
    final response = await _client.post(uri, headers: headers, body: body);
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw YouVersionException(
        'Requisição falhou',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw YouVersionException(
        'Resposta inesperada (não é um objeto JSON)',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    return decoded;
  }

  void close() => _client.close();
}
