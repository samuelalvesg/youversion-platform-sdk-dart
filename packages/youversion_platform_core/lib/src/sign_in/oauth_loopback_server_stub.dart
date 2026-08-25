/// Web/`dart:io`-less stub for [OAuthLoopbackServer] - see
/// `oauth_loopback_server.dart`'s doc comment. Exported instead of the
/// real implementation whenever `dart:io` isn't available (conditional
/// export in `youversion_platform_core.dart`), so importing this
/// package's top-level barrel never fails to compile for Flutter Web just
/// because this one desktop-only class exists - it just isn't usable
/// there. `start()` throws immediately rather than doing anything.
class OAuthLoopbackServer {
  OAuthLoopbackServer._(this.redirectUri);

  final Uri redirectUri;

  static Future<OAuthLoopbackServer> start({required int port, String path = '/callback'}) {
    throw UnsupportedError('OAuthLoopbackServer needs dart:io - not available on this platform (e.g. web).');
  }

  Future<Uri> waitForCallback({Duration timeout = const Duration(minutes: 5)}) =>
      throw UnsupportedError('unreachable - start() always throws first');

  Future<void> dispose() async {}
}
