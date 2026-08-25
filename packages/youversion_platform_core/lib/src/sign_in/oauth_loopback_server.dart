import 'dart:async';
import 'dart:io';

/// A temporary local HTTP server that catches a single OAuth redirect on
/// `http://127.0.0.1:<port>/<path>` - the RFC 8252 §7.3 "loopback
/// interface redirection" pattern desktop apps use in place of a
/// custom-scheme deep link (which the OS never registers for a desktop
/// build the way it does on Android/iOS). No web-server package
/// dependency - `dart:io`'s own `HttpServer` is enough for a
/// single-request, short-lived listener like this.
///
/// Not usable on Flutter Web (`dart:io` isn't available there) or on
/// mobile (no loopback interface to redirect to from the system browser
/// in the same way) - desktop only. Mirrors the pattern used by
/// Symmetris' own Flutter desktop app (`OAuthLoopbackServer`,
/// `features/auth/services/oauth_loopback_server.dart`), reimplemented
/// here rather than shared since that app isn't a dependency of this SDK.
///
/// **Requires the App Key's registered `redirect_uri` to actually be**
/// `http://127.0.0.1:<port>/<path>` for the [port]/[path] this is started
/// with - `/auth/authorize` will reject anything else. Whether YouVersion's
/// OAuth server matches the loopback redirect_uri leniently (RFC 8252
/// says the *port* specifically shouldn't need to be pre-registered,
/// scheme/host/path is enough) or requires an exact string match
/// including the port is **not confirmed** - this class takes a fixed
/// [port] rather than binding to an OS-assigned free one (`port: 0`) so
/// it works either way; if live testing later confirms YouVersion ignores
/// the port, this can switch to a dynamic one.
class OAuthLoopbackServer {
  OAuthLoopbackServer._(this._server, this.redirectUri, this._path);

  final HttpServer _server;
  final String _path;

  /// The exact `redirect_uri` to pass to `YouVersionSignIn.buildAuthorizationUrl`'s
  /// `YouVersionSignIn(redirectUri: ...)` construction - must match what's
  /// registered for the App Key.
  final Uri redirectUri;

  /// Starts listening on `http://127.0.0.1:[port][path]`. Throws
  /// [SocketException] if [port] is already in use.
  static Future<OAuthLoopbackServer> start({required int port, String path = '/callback'}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    return OAuthLoopbackServer._(server, Uri(scheme: 'http', host: '127.0.0.1', port: port, path: path), path);
  }

  /// Waits for the redirect request on [_path] specifically, responds with
  /// a plain "you can close this tab" page, then closes the server.
  /// Returns the full request URI (query parameters intact - `code`/
  /// `state`/etc, same shape as a pasted callback URL). Throws
  /// [TimeoutException] if nothing arrives within [timeout] - the server
  /// is closed either way.
  ///
  /// **Not just `_server.first`** - confirmed live, unlike a callback
  /// redirect from a backend an app controls itself (which only ever
  /// issues one clean request here), a real third-party OAuth/login
  /// page's *browser* can issue other requests to this origin first
  /// (favicon, a CORS preflight, etc.) before the actual navigation
  /// request lands. Grabbing whichever request arrives first answered the
  /// wrong one and closed the server before the real callback ever got a
  /// response ("didn't respond on the port" - the port was already
  /// closed by the time the real request came in). This loops, answering
  /// (`404`) and discarding anything that isn't [_path] without closing
  /// the server, only resolving/closing on an actual match.
  Future<Uri> waitForCallback({Duration timeout = const Duration(minutes: 5)}) async {
    try {
      final deadline = DateTime.now().add(timeout);
      await for (final request in _server.timeout(timeout)) {
        if (request.uri.path != _path) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          if (DateTime.now().isAfter(deadline)) throw TimeoutException('No callback on $_path within $timeout');
          continue;
        }
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write('<html><body>Signed in - you can close this tab.</body></html>');
        await request.response.close();
        // `request.uri` is path+query only (no scheme/host) - resolve
        // against `redirectUri` to get the full URI back, matching what a
        // pasted callback URL would look like.
        return redirectUri.replace(queryParameters: request.uri.queryParameters);
      }
      throw TimeoutException('No callback on $_path within $timeout');
    } finally {
      await dispose();
    }
  }

  Future<void> dispose() => _server.close(force: true);
}
