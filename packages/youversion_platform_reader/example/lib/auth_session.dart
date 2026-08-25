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

  /// Tries to restore a session from a previously saved refresh token.
  /// Silently signs out (no error surfaced) if the refresh fails - the
  /// user just sees the signed-out state and can sign in again.
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
    } catch (_) {
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
