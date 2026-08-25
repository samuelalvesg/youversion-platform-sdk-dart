import 'permission.dart';

/// Result of exchanging a code (or refreshing) for tokens on the Sign-In
/// API.
///
/// [idToken] is only populated on the initial `code` exchange - the
/// refresh endpoint (`grant_type=refresh_token`) does not return a new
/// id_token (confirmed against the official Kotlin SDK, `RefreshTokenResponse`
/// doesn't have this field). Store the [idToken] from the initial exchange
/// to decode the identity after a refresh.
///
/// [grantedPermissions] comes from the `granted_permissions` query of the
/// callback redirect (not from this response's body) - optional
/// permissions (e.g. `highlights`) may have been denied by the user
/// without failing the login; only populated when
/// `YouVersionSignIn.exchangeCode` receives the full callback URL.
class YouVersionToken {
  YouVersionToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.scope,
    this.idToken,
    this.grantedPermissions = const {},
  });

  factory YouVersionToken.fromJson(
    Map<String, dynamic> json, {
    Set<YouVersionPermission> grantedPermissions = const {},
  }) {
    return YouVersionToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      // Confirmed live: the server sends `expires_in` as a string, not a
      // JSON number, despite `RefreshTokenResponse`/`TokenResponse` typing
      // it as an int in both Kotlin and this package's own doc comment
      // assuming a plain int cast was safe. Parses either shape.
      expiresIn: switch (json['expires_in']) {
        final int value => value,
        final String value => int.parse(value),
        final num value => value.toInt(),
        _ => throw FormatException('expires_in has an unexpected type: ${json['expires_in']}'),
      },
      scope: json['scope'] as String? ?? '',
      idToken: json['id_token'] as String?,
      grantedPermissions: grantedPermissions,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String scope;
  final String? idToken;
  final Set<YouVersionPermission> grantedPermissions;
}
