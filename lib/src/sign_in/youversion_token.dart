/// Resultado da troca de código (ou refresh) por tokens na Sign-In API.
///
/// [idToken] só vem preenchido na troca inicial do `code` - o endpoint de
/// refresh (`grant_type=refresh_token`) não devolve um novo id_token
/// (confirmado contra o SDK oficial Kotlin, `RefreshTokenResponse` não tem
/// esse campo). Guarde o [idToken] da troca inicial pra decodificar a
/// identidade depois de um refresh.
class YouVersionToken {
  YouVersionToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.scope,
    this.idToken,
  });

  factory YouVersionToken.fromJson(Map<String, dynamic> json) {
    return YouVersionToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      scope: json['scope'] as String? ?? '',
      idToken: json['id_token'] as String?,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String scope;
  final String? idToken;
}
