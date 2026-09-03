import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

/// Signed-in session state for the example app: current token/identity,
/// persisted via `shared_preferences` so sign-in survives a restart (tries
/// `refreshToken` on startup if a refresh token was saved).
///
/// Plain `ChangeNotifier` - same "no state-management dependency" pattern
/// used throughout this SDK (e.g. `BibleReaderController`), not a
/// Riverpod/Provider/Bloc requirement.
class AuthSession extends ChangeNotifier {
  AuthSession(this._signIn);

  static const _accessTokenKey = 'youversion_example_access_token';
  static const _refreshTokenKey = 'youversion_example_refresh_token';
  static const _idTokenKey = 'youversion_example_id_token';

  final YouVersionSignIn _signIn;

  YouVersionToken? _token;
  YouVersionIdentity? _identity;
  bool _isLoading = true;

  YouVersionToken? get token => _token;
  YouVersionIdentity? get identity => _identity;
  bool get isSignedIn => _token != null;
  bool get isLoading => _isLoading;

  /// Set right before `restore()` signs out because a saved refresh token
  /// failed - `null` for every other sign-out (explicit user action, or no
  /// saved token at all). Lets the UI (`SignInPage`) tell "you got signed
  /// out because your session expired" apart from "you were never signed
  /// in" instead of just landing on the same silent login screen either
  /// way - real bug this fixed (found downstream in an app built on this
  /// example, `bible_with_me`, 2026-09-03): a stale/invalid refresh token
  /// cleared the session with zero visible signal, which also made
  /// `BibleExplorerPage` silently stop showing highlights (its
  /// `userAccessToken` went `null` at the same time) with nothing tying the
  /// two symptoms together for the user. Call [clearSignOutReason] once the
  /// UI has shown it.
  bool _sessionExpired = false;
  bool get sessionExpired => _sessionExpired;
  void clearSignOutReason() {
    if (!_sessionExpired) return;
    _sessionExpired = false;
    notifyListeners();
  }

  /// Tries to restore a session from a previously saved refresh token.
  /// Signs out if the refresh fails - the real error is logged (was
  /// silently swallowed before) and `sessionExpired` is set so the UI can
  /// explain why, instead of just showing the signed-out state with no
  /// context.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    final idToken = prefs.getString(_idTokenKey);
    if (refreshToken == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    try {
      final refreshed = await _signIn.refreshToken(refreshToken);
      // The refresh endpoint doesn't return a new id_token - reuse the
      // saved one to decode identity, per YouVersionToken's own doc
      // comment.
      final token = YouVersionToken(
        accessToken: refreshed.accessToken,
        refreshToken: refreshed.refreshToken,
        expiresIn: refreshed.expiresIn,
        scope: refreshed.scope,
        idToken: idToken,
      );
      await _apply(token);
    } catch (error, stackTrace) {
      debugPrint('AuthSession.restore: refresh token failed, signing out: $error\n$stackTrace');
      _sessionExpired = true;
      await signOut();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(YouVersionToken token) => _apply(token);

  Future<void> _apply(YouVersionToken token) async {
    _token = token;
    _identity = token.idToken != null ? _signIn.decodeIdentity(token.idToken!) : _identity;
    _sessionExpired = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token.accessToken);
    await prefs.setString(_refreshTokenKey, token.refreshToken);
    if (token.idToken != null) await prefs.setString(_idTokenKey, token.idToken!);
    notifyListeners();
  }

  Future<void> signOut() async {
    _token = null;
    _identity = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_idTokenKey);
    notifyListeners();
  }
}
