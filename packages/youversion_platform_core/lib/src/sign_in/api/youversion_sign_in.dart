import 'dart:convert';

import '../../http/youversion_exception.dart';
import '../../http/youversion_http_client.dart';
import '../../http/youversion_sdk_headers.dart';
import '../models/permission.dart';
import '../models/youversion_identity.dart';
import '../models/youversion_token.dart';
import '../pkce.dart';

/// Sign-In API (`/auth/authorize`, `/auth/token`) - Authorization Code +
/// PKCE, public client (no `client_secret`).
///
/// Contract validated against platform-sdk-kotlin, `users/api/UsersEndpoints.kt`
/// (cross-checked with platform-sdk-swift `Users.swift`, platform-sdk-react
/// `Users.ts`/`permissions.ts`) - not just the documentation.
///
/// This package only builds URLs and exchanges/decodes tokens - it does not
/// open a browser nor capture the deep link back. That is the consumer
/// app's responsibility (Flutter: `url_launcher` + capturing the redirect
/// via deep link/route).
///
/// Assumes a real HTTPS `redirectUri` controlled by the app itself.
/// **Not always a direct-`code`-in-the-query redirect** - confirmed live
/// that at least some App Key configurations redirect with only `state`/
/// `granted_permissions` first, requiring the same extra `/auth/callback`
/// hop the native SDKs (Android/iOS) always perform - see
/// [YouVersionSignIn.resolveCallback]. Call it whenever `exchangeCode`'s
/// `code` isn't present in the redirect yet.
class YouVersionSignIn {
  YouVersionSignIn({
    required this.appKey,
    required this.redirectUri,
    this.installationId,
    Uri? baseUri,
    YouVersionHttpClient? httpClient,
  })  : _baseUri = baseUri ?? Uri.parse('https://api.youversion.com'),
        _http = httpClient ?? YouVersionHttpClient();

  /// YouVersion Platform App Key (same value used as `client_id` in the
  /// OAuth protocol and as the `X-YVP-App-Key` header in the Content API).
  final String appKey;
  final Uri redirectUri;

  /// Persistent UUID per installation (optional - the package is
  /// storage-agnostic, generate/persist it in the consumer app). Sent as
  /// the `x-yvp-installation-id` query param in `/auth/authorize` and as a
  /// header on every call, same as the official SDKs.
  final String? installationId;

  final Uri _baseUri;
  final YouVersionHttpClient _http;

  /// Builds the authorization URL and the corresponding PKCE pair. Store
  /// [PkceAuthorizationRequest.codeVerifier] and the returned `state`/`nonce`
  /// (in memory/session) - they will be needed in [exchangeCode] and when
  /// validating the `id_token`.
  ///
  /// `openid` is always included. `highlights`, if present in [permissions],
  /// is treated as optional (goes in `requested_permissions`, not in `scope`)
  /// - same rule applied to any permission outside the
  /// `{openid, profile, email}` set (`bibles`, `votd`, `demographics`,
  /// `bible_activity` are also optional in that sense).
  PkceAuthorizationRequest buildAuthorizationUrl({
    Set<YouVersionPermission> permissions = const {
      YouVersionPermission.profile,
      YouVersionPermission.email,
    },
  }) {
    final pkce = PkcePair.generate();
    final state = generateRandomToken();
    final nonce = generateRandomToken();

    const required = {
      YouVersionPermission.openid,
      YouVersionPermission.profile,
      YouVersionPermission.email,
    };
    final requiredScope = ({YouVersionPermission.openid, ...permissions}..retainWhere(required.contains))
        .map((p) => p.rawValue)
        .toList()
      ..sort();
    final requestedOptional = permissions.where((p) => !required.contains(p)).map((p) => p.rawValue).toList()..sort();

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
        if (requestedOptional.isNotEmpty) 'requested_permissions': requestedOptional.join(','),
        'require_user_interaction': 'true',
        if (installationId != null) 'x-yvp-installation-id': installationId!,
      },
    );

    return PkceAuthorizationRequest(
      authorizationUrl: uri,
      codeVerifier: pkce.codeVerifier,
      state: state,
      nonce: nonce,
    );
  }

  /// Resolves the intermediate `/auth/callback` hop - **required** for at
  /// least some App Key configurations. The initial `/auth/authorize`
  /// redirect can land on [redirectUri] with only `state`/
  /// `granted_permissions` and **no `code`** - confirmed live (curling
  /// `https://api.youversion.com/auth/callback?state=...&granted_permissions=...`
  /// with redirects disabled returns a `302` whose `Location` header
  /// finally carries `code`), and matches Kotlin's `UsersEndpoints.kt`
  /// (`obtainLocation`/`obtainCode`), which always performs this exact
  /// hop - this package's own doc comment previously assumed it was never
  /// needed ("the code arrives directly as a query param"), which turned
  /// out to be wrong for the App Key this was tested against.
  ///
  /// Call this first when [exchangeCode]'s `code` isn't in the redirect
  /// URL yet; parse the *returned* URI's `code` (and `state`) instead.
  ///
  /// **Not usable on Flutter Web** - see
  /// [YouVersionHttpClient.getRedirectLocation]'s doc comment; browsers
  /// don't expose a cross-origin manual redirect's `Location` header to
  /// JS at all, a platform restriction this package can't route around.
  Future<Uri> resolveCallback(Uri redirectUri) {
    final uri = _baseUri.replace(path: '/auth/callback', queryParameters: redirectUri.queryParameters);
    return _http.getRedirectLocation(uri);
  }

  /// Reads `granted_permissions` from the callback URL - only covers the
  /// OPTIONAL permissions (e.g. `highlights`) - the required ones
  /// (`openid`/`profile`/`email`) don't go through here, they're already
  /// guaranteed in the token's `scope`. See
  /// `YouVersionPermission.parseGrantedPermissions`.
  static Set<YouVersionPermission> parseGrantedPermissions(Uri callbackUri) =>
      YouVersionPermission.parseGrantedPermissions(callbackUri);

  /// Exchanges the redirect's `code` for tokens. [codeVerifier] must be the
  /// same one generated in [buildAuthorizationUrl] for this same login
  /// attempt.
  ///
  /// If [expectedState]/[expectedNonce] are passed, validates `state`
  /// (against what came in the redirect - pass the `state` received in
  /// [receivedState]) and `nonce` (against the `nonce` claim of the
  /// returned `id_token`), throwing [YouVersionException] on mismatch
  /// (protection against replay/CSRF attacks).
  ///
  /// [grantedPermissions] - pass the result of [parseGrantedPermissions]
  /// applied to the callback URL, if you want to know which optional
  /// permissions were actually granted.
  Future<YouVersionToken> exchangeCode({
    required String code,
    required String codeVerifier,
    String? receivedState,
    String? expectedState,
    String? expectedNonce,
    Set<YouVersionPermission> grantedPermissions = const {},
  }) async {
    if (expectedState != null && receivedState != expectedState) {
      throw YouVersionException(
        'State mismatch - possible CSRF',
        reason: YouVersionErrorReason.invalidResponse,
      );
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
      headers: _headers,
    );
    final token = YouVersionToken.fromJson(
      json,
      grantedPermissions: grantedPermissions,
    );

    if (expectedNonce != null && token.idToken != null) {
      final claims = _decodeClaims(token.idToken!);
      if (claims['nonce'] != expectedNonce) {
        throw YouVersionException(
          'Nonce mismatch - possible replay attack',
          reason: YouVersionErrorReason.invalidResponse,
        );
      }
    }

    return token;
  }

  /// Renews the access token from a valid `refresh_token`. The response
  /// does not include a new `id_token` - reuse the [YouVersionToken.idToken]
  /// from the initial exchange to decode the identity.
  Future<YouVersionToken> refreshToken(String refreshToken) async {
    final uri = _baseUri.replace(path: '/auth/token');
    final json = await _http.postForm(
      uri,
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': appKey,
      },
      headers: _headers,
      reasonForStatus: (_) => YouVersionErrorReason.missingAuthentication,
    );
    return YouVersionToken.fromJson(json);
  }

  /// Decodes the `id_token` claims into a [YouVersionIdentity].
  ///
  /// Does NOT verify the token's signature - assumes it came directly from
  /// the HTTPS response of [exchangeCode] (trusted channel). If you're going
  /// to pass this token between services and need to validate the
  /// signature, validate it against the JWKS at
  /// `https://api.youversion.com/.well-known/jwks.json` before trusting the
  /// claims.
  YouVersionIdentity decodeIdentity(String idToken) {
    return YouVersionIdentity.fromClaims(_decodeClaims(idToken));
  }

  Map<String, String> get _headers => youVersionSdkHeaders(appKey: appKey, installationId: installationId);

  Map<String, dynamic> _decodeClaims(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) {
      throw YouVersionException(
        'Token does not appear to be a valid JWT',
        reason: YouVersionErrorReason.invalidResponse,
      );
    }
    final normalized = base64Url.normalize(parts[1]);
    final payload = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(payload) as Map<String, dynamic>;
  }

  void close() => _http.close();
}

/// Already-built authorization URL + PKCE/state/nonce material that the
/// caller needs to store until the redirect comes back.
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
