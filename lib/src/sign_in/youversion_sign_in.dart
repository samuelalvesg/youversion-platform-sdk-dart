import 'dart:convert';

import '../http/youversion_exception.dart';
import '../http/youversion_http_client.dart';
import 'permission.dart';
import 'pkce.dart';
import 'youversion_identity.dart';
import 'youversion_token.dart';

/// Sign-In API (`/auth/authorize`, `/auth/token`) - Authorization Code +
/// PKCE, cliente público (sem `client_secret`). Contrato validado contra o
/// SDK oficial Kotlin (`UsersEndpoints.kt`), não só a documentação.
///
/// Este pacote só monta URLs e troca/decodifica tokens - não abre navegador
/// nem captura deep link de volta. Isso fica por conta do app consumidor
/// (Flutter: `url_launcher` + captura do redirect via deep link/rota).
///
/// Assume um `redirectUri` HTTPS real que o próprio app controla, onde o
/// `code` chega direto como query param (fluxo Authorization Code padrão).
/// Os SDKs nativos (Android/iOS) fazem um hop extra via `/auth/callback`
/// pra contornar limitações de Universal/App Link nesses SO's - não
/// necessário aqui.
class YouVersionSignIn {
  YouVersionSignIn({
    required this.appKey,
    required this.redirectUri,
    Uri? baseUri,
    YouVersionHttpClient? httpClient,
  })  : _baseUri = baseUri ?? Uri.parse('https://api.youversion.com'),
        _http = httpClient ?? YouVersionHttpClient();

  /// App Key da YouVersion Platform (mesmo valor usado como `client_id` no
  /// protocolo OAuth e como header `X-YVP-App-Key` na Content API).
  final String appKey;
  final Uri redirectUri;
  final Uri _baseUri;
  final YouVersionHttpClient _http;

  /// Monta a URL de autorização e o par PKCE correspondente. Guarde
  /// [PkceAuthorizationRequest.codeVerifier] e o `state`/`nonce` retornados
  /// (em memória/sessão) - serão necessários em [exchangeCode] e na
  /// validação do `id_token`.
  ///
  /// `openid` é sempre incluída. `highlights`, se presente em [permissions],
  /// é tratada como opcional (vai em `requested_permissions`, não em `scope`).
  PkceAuthorizationRequest buildAuthorizationUrl({
    Set<YouVersionPermission> permissions = const {
      YouVersionPermission.profile,
      YouVersionPermission.email,
    },
  }) {
    final pkce = PkcePair.generate();
    final state = generateRandomToken();
    final nonce = generateRandomToken();

    const optional = {YouVersionPermission.highlights};
    final requiredScope = ({YouVersionPermission.openid, ...permissions}
          ..removeAll(optional))
        .map((p) => p.rawValue)
        .toList()
      ..sort();
    final requestedOptional = permissions
        .intersection(optional)
        .map((p) => p.rawValue)
        .toList()
      ..sort();

    final uri = _baseUri.replace(
      path: '/auth/authorize',
      queryParameters: {
        'response_type': 'code',
        'client_id': appKey,
        'redirect_uri': redirectUri.toString(),
        'scope': requiredScope.join(' '),
        'state': state,
        'nonce': nonce,
        'code_challenge': pkce.codeChallenge,
        'code_challenge_method': 'S256',
        if (requestedOptional.isNotEmpty)
          'requested_permissions': requestedOptional.join(','),
        'require_user_interaction': 'true',
      },
    );

    return PkceAuthorizationRequest(
      authorizationUrl: uri,
      codeVerifier: pkce.codeVerifier,
      state: state,
      nonce: nonce,
    );
  }

  /// Troca o `code` do redirect por tokens. [codeVerifier] deve ser o mesmo
  /// gerado em [buildAuthorizationUrl] pra essa mesma tentativa de login.
  ///
  /// Se [expectedState]/[expectedNonce] forem passados, valida `state` (contra
  /// o que veio no redirect - passe o `state` recebido em [receivedState]) e
  /// `nonce` (contra o claim `nonce` do `id_token` retornado), lançando
  /// [YouVersionException] em caso de divergência (proteção contra replay/CSRF).
  Future<YouVersionToken> exchangeCode({
    required String code,
    required String codeVerifier,
    String? receivedState,
    String? expectedState,
    String? expectedNonce,
  }) async {
    if (expectedState != null && receivedState != expectedState) {
      throw YouVersionException('State mismatch - possível CSRF');
    }

    final uri = _baseUri.replace(path: '/auth/token');
    final json = await _http.postForm(
      uri,
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri.toString(),
        'client_id': appKey,
        'code_verifier': codeVerifier,
      },
    );
    final token = YouVersionToken.fromJson(json);

    if (expectedNonce != null && token.idToken != null) {
      final claims = _decodeClaims(token.idToken!);
      if (claims['nonce'] != expectedNonce) {
        throw YouVersionException('Nonce mismatch - possível replay attack');
      }
    }

    return token;
  }

  /// Renova o access token a partir de um `refresh_token` válido. A resposta
  /// não inclui um novo `id_token` - reaproveite o [YouVersionToken.idToken]
  /// da troca inicial pra decodificar a identidade.
  Future<YouVersionToken> refreshToken(String refreshToken) async {
    final uri = _baseUri.replace(path: '/auth/token');
    final json = await _http.postForm(
      uri,
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': appKey,
      },
    );
    return YouVersionToken.fromJson(json);
  }

  /// Decodifica os claims do `id_token` em uma [YouVersionIdentity].
  ///
  /// NÃO verifica a assinatura do token - assume que ele veio direto da
  /// resposta HTTPS de [exchangeCode] (canal confiável). Se for repassar
  /// esse token entre serviços e precisar validar a assinatura, valide
  /// contra o JWKS em `https://api.youversion.com/.well-known/jwks.json`
  /// antes de confiar nos claims.
  YouVersionIdentity decodeIdentity(String idToken) {
    return YouVersionIdentity.fromClaims(_decodeClaims(idToken));
  }

  Map<String, dynamic> _decodeClaims(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) {
      throw YouVersionException('Token não parece ser um JWT válido');
    }
    final normalized = base64Url.normalize(parts[1]);
    final payload = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(payload) as Map<String, dynamic>;
  }

  void close() => _http.close();
}

/// URL de autorização já montada + material PKCE/state/nonce que o
/// chamador precisa guardar até o redirect voltar.
class PkceAuthorizationRequest {
  PkceAuthorizationRequest({
    required this.authorizationUrl,
    required this.codeVerifier,
    required this.state,
    required this.nonce,
  });

  final Uri authorizationUrl;
  final String codeVerifier;
  final String state;
  final String nonce;
}
