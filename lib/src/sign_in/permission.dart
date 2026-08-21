/// Permissões do fluxo Sign-In. `openid` é sempre incluída automaticamente
/// pelo pacote; `highlights` é "opcional" no sentido em que o servidor
/// aceita o usuário negá-la sem falhar o login inteiro - por isso vai no
/// parâmetro `requested_permissions`, separado do `scope` padrão OAuth
/// (mesma separação usada no SDK oficial Kotlin).
enum YouVersionPermission {
  openid('openid'),
  profile('profile'),
  email('email'),
  highlights('highlights');

  const YouVersionPermission(this.rawValue);

  final String rawValue;
}
