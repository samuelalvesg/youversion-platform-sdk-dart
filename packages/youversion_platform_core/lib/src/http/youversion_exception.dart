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

  /// `429 Too Many Requests` - confirmed against the official error-codes
  /// docs (developers.youversion.com/error-codes), which document a
  /// `Retry-After` header alongside it. Applied uniformly across every
  /// client regardless of that client's own `reasonForStatus` (rate
  /// limiting is a protocol-level condition, not endpoint-specific
  /// semantics like `401`/`403` are).
  rateLimited,

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
    this.retryAfter,
  });

  final String message;
  final int? statusCode;
  final String? body;
  final YouVersionErrorReason reason;

  /// Parsed from the `Retry-After` header on a `429` response (seconds
  /// form only - confirmed live, the API sends an integer, not an HTTP
  /// date). `null` when the header was absent or not `reason ==
  /// rateLimited`.
  final Duration? retryAfter;

  @override
  String toString() => 'YouVersionException($reason, $statusCode): $message';
}
