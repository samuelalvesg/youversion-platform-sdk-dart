/// Classification of the failure reason, mirroring the taxonomy used by
/// the official SDKs (`YouVersionNetworkException.Reason` in Kotlin,
/// `YouVersionAPIError` in Swift) - the same HTTP status means different
/// things on different endpoints (e.g. `401` on Highlights is "not
/// authenticated", recoverable with a refresh; on Data Exchange it's
/// "token denied", permanent), so the clients map it to this instead of
/// leaving the caller to decide based solely on `statusCode`.
enum YouVersionErrorReason {
  /// No access token / token missing or expired with no refresh available.
  missingAuthentication,

  /// Authenticated, but without permission for this resource (e.g. an
  /// optional permission like `highlights` was not granted at login).
  notPermitted,

  /// Server refused to process the request (validation, generic `4xx`).
  cannotDownload,

  /// Response came back, but in an unexpected format (not the documented
  /// JSON/envelope for the endpoint).
  invalidResponse,

  /// Any other network/server error not classified above.
  unknown,
}

/// Exception thrown by any call to the YouVersion Platform APIs.
class YouVersionException implements Exception {
  YouVersionException(
    this.message, {
    this.statusCode,
    this.body,
    this.reason = YouVersionErrorReason.unknown,
  });

  final String message;
  final int? statusCode;
  final String? body;
  final YouVersionErrorReason reason;

  @override
  String toString() => 'YouVersionException($reason, $statusCode): $message';
}
