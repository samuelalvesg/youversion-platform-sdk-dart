/// Sign-In flow permissions. `openid` is always automatically included by
/// the package; `highlights` is "optional" in the sense that the server
/// allows the user to deny it without failing the whole login - that's why
/// it goes in the `requested_permissions` parameter, separate from the
/// standard OAuth `scope` (same separation used in the official Kotlin
/// SDK).
///
/// Contract validated against platform-sdk-kotlin,
/// `users/model/SignInWithYouVersionPermission.kt`, with `bibles`/`votd`/
/// `demographics`/`bible_activity` confirmed via platform-sdk-react
/// `SignInWithYouVersionResult.ts`.
enum YouVersionPermission {
  openid('openid'),
  profile('profile'),
  email('email'),
  highlights('highlights'),
  bibles('bibles'),
  votd('votd'),
  demographics('demographics'),
  bibleActivity('bible_activity');

  const YouVersionPermission(this.rawValue);

  final String rawValue;

  static YouVersionPermission? fromRawValue(String rawValue) {
    for (final permission in values) {
      if (permission.rawValue == rawValue) return permission;
    }
    return null;
  }

  /// Reads `granted_permissions` from a callback URL (Sign-In or Data
  /// Exchange) - accepts both `granted_permissions=a,b` and
  /// `granted_permissions[]=a&granted_permissions[]=b` (the server uses
  /// both notations depending on which SDK makes the call, confirmed by
  /// cross-checking platform-sdk-kotlin and platform-sdk-react).
  static Set<YouVersionPermission> parseGrantedPermissions(Uri callbackUri) {
    final bracketValues = callbackUri.queryParametersAll['granted_permissions[]'];
    final flatValue = callbackUri.queryParameters['granted_permissions'];
    final raw = <String>{
      ...?bracketValues,
      ...?flatValue?.split(RegExp(r'[,\s]+')),
    }..removeWhere((s) => s.isEmpty);

    return raw.map(fromRawValue).whereType<YouVersionPermission>().toSet();
  }
}
