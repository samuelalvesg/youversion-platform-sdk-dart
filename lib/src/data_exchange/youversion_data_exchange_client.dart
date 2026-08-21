import '../http/youversion_http_client.dart';

/// Data Exchange API - sincronização de highlights do usuário. Requer um
/// access token de usuário já autenticado via `YouVersionSignIn`. Contrato
/// validado contra o SDK oficial Kotlin (`DataExchangeEndpoints.kt`).
///
/// Fluxo de 3 passos: 1) [createToken] cria um token curto de uso único;
/// 2) o app abre [buildApprovalUrl] no navegador pro usuário aprovar; 3) o
/// navegador redireciona de volta pro callback URL configurado no console
/// de desenvolvedor da YouVersion (não é passado por parâmetro aqui - é
/// registrado previamente, ao contrário do redirect_uri do Sign-In). Este
/// pacote não abre o navegador - isso é responsabilidade do app consumidor.
class YouVersionDataExchangeClient {
  YouVersionDataExchangeClient({
    required String appKey,
    Uri? baseUri,
    YouVersionHttpClient? httpClient,
  })  : _appKey = appKey,
        _baseUri = baseUri ?? Uri.parse('https://api.youversion.com'),
        _http = httpClient ?? YouVersionHttpClient();

  final String _appKey;
  final Uri _baseUri;
  final YouVersionHttpClient _http;

  /// Cria um `data_exchange` token de curta duração e uso único.
  /// [userAccessToken] é o access token do usuário (obtido via
  /// `YouVersionSignIn`), enviado como `Authorization: Bearer`.
  Future<String> createToken({
    required String userAccessToken,
    Set<String> requestedPermissions = const {'highlights'},
  }) async {
    final uri = _baseUri.replace(
      path: '/data-exchange/token',
      queryParameters: {'app-key': _appKey},
    );
    final json = await _http.postJson(
      uri,
      headers: {'Authorization': 'Bearer $userAccessToken'},
      body: {'requested_permissions': requestedPermissions.toList()..sort()},
    );
    return json['token'] as String;
  }

  /// Monta a URL da página de aprovação (passo 2 do fluxo) que o app deve
  /// abrir no navegador/webview pro usuário confirmar o compartilhamento.
  Uri buildApprovalUrl(String token) {
    return _baseUri.replace(
      path: '/data-exchange',
      queryParameters: {
        'token': token,
        'app_key': _appKey,
        'x-yvp-app-key': _appKey,
      },
    );
  }

  void close() => _http.close();
}
