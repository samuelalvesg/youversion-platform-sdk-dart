import '../../http/youversion_exception.dart';
import '../../http/youversion_http_client.dart';
import '../../sign_in/models/permission.dart';
import '../models/data_exchange_result.dart';

/// Data Exchange API - syncs the user's highlights. Requires a user
/// access token already authenticated via `YouVersionSignIn`.
///
/// Contract validated against platform-sdk-kotlin,
/// `dataexchange/api/DataExchangeEndpoints.kt`, cross-checked against
/// platform-sdk-react `data-exchange.ts`.
///
/// 3-step flow: 1) [createToken] creates a short-lived, single-use token;
/// 2) the app opens [buildApprovalUrl] in the browser for the user to
/// approve; 3) the browser redirects back to the callback URL configured
/// in the YouVersion developer console (not passed as a parameter here -
/// it's registered beforehand, unlike Sign-In's redirect_uri) - use
/// [parseCallback] on that return URL. This package does not open the
/// browser - that's the consuming app's responsibility.
///
/// **Security note** (there's no way to enforce this in a
/// storage-agnostic package, but it's the consuming app's responsibility
/// to observe): the consent redirect is fire-and-forget - if the logged-in
/// user changes between the start of the flow ([createToken]) and the
/// callback ([parseCallback]), the grant may end up applied to the wrong
/// user. Record which `sub` (via `YouVersionSignIn.decodeIdentity`)
/// started the flow and compare it against the user logged in at callback
/// time before trusting the result (same pattern used by the React SDK,
/// which records the "initiator").
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

  /// Creates a short-lived, single-use `data_exchange` token.
  /// [userAccessToken] is the user's access token (obtained via
  /// `YouVersionSignIn`), sent as `Authorization: Bearer`.
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
      reasonForStatus: (status) => status == 401
          ? YouVersionErrorReason.notPermitted
          : YouVersionErrorReason.cannotDownload,
    );
    return json['token'] as String;
  }

  /// Builds the approval page URL (step 2 of the flow) that the app should
  /// open in the browser/webview for the user to confirm sharing.
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

  /// Parses the redirect back from step 3 (`data_exchange_status` and
  /// `granted_permissions` in the query). See the security note in the
  /// class doc before trusting the result without checking the logged-in
  /// user.
  DataExchangeResult parseCallback(Uri callbackUri) {
    final statusRaw = callbackUri.queryParameters['data_exchange_status'];
    final status = statusRaw == 'granted'
        ? DataExchangeStatus.granted
        : statusRaw == 'cancel'
            ? DataExchangeStatus.cancelled
            : DataExchangeStatus.failure;

    return DataExchangeResult(
      status: status,
      grantedPermissions: YouVersionPermission.parseGrantedPermissions(callbackUri),
    );
  }

  void close() => _http.close();
}
