import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PKCE pair (RFC 7636) - `codeVerifier` stays only in the app,
/// `codeChallenge` goes in the authorization URL.
class PkcePair {
  PkcePair._(this.codeVerifier, this.codeChallenge);

  factory PkcePair.generate() {
    final random = Random.secure();
    final verifierBytes = List<int>.generate(64, (_) => random.nextInt(256));
    final codeVerifier = base64UrlNoPad(verifierBytes);
    final challengeBytes = sha256.convert(utf8.encode(codeVerifier)).bytes;
    final codeChallenge = base64UrlNoPad(challengeBytes);
    return PkcePair._(codeVerifier, codeChallenge);
  }

  final String codeVerifier;
  final String codeChallenge;

  static String base64UrlNoPad(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

/// Generates a short random value for `state`/`nonce` (doesn't need to be
/// PKCE, just unpredictable).
String generateRandomToken({int length = 32}) {
  final random = Random.secure();
  final bytes = List<int>.generate(length, (_) => random.nextInt(256));
  return PkcePair.base64UrlNoPad(bytes);
}
