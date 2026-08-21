/// Identidade do usuário, decodificada do JWT de acesso da Sign-In API.
///
/// IMPORTANTE: a YouVersion não emite claim `email_verified` nesse token -
/// [email] pode não ter posse verificada pelo provedor. Nunca use [email]
/// pra auto-vincular/mesclar contas por igualdade de string sem uma
/// confirmação adicional (mesmo cuidado já aplicado a outros provedores
/// OAuth que não garantem e-mail verificado, ex.: Microsoft, Spotify).
class YouVersionIdentity {
  YouVersionIdentity({
    required this.sub,
    required this.yvpId,
    this.email,
    this.name,
    this.profilePicture,
  });

  factory YouVersionIdentity.fromClaims(Map<String, dynamic> claims) {
    return YouVersionIdentity(
      sub: claims['sub'] as String,
      yvpId: claims['yvp_id'] as String? ?? claims['sub'] as String,
      email: claims['email'] as String?,
      name: claims['name'] as String?,
      // Claim real é "picture" (confirmado no SDK oficial Kotlin,
      // UsersEndpoints.kt) - não "profile_picture" como documentação
      // antiga sugeria.
      profilePicture: claims['picture'] as String?,
    );
  }

  /// Identificador estável do usuário (idêntico a [yvpId]).
  final String sub;

  /// Chave primária estável do usuário na YouVersion Platform.
  final String yvpId;

  /// E-mail declarado - NÃO verificado, ver aviso da classe.
  final String? email;

  final String? name;
  final String? profilePicture;
}
