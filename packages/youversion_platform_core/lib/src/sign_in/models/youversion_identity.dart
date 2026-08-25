/// User identity, decoded from the Sign-In API's access JWT.
///
/// IMPORTANT: YouVersion does not issue an `email_verified` claim on this
/// token - [email] may not have ownership verified by the provider. Never
/// use [email] to auto-link/merge accounts by string equality without an
/// additional confirmation (same caution already applied to other OAuth
/// providers that don't guarantee a verified email, e.g. Microsoft,
/// Spotify).
///
/// Contract validated against platform-sdk-kotlin, `users/api/UsersEndpoints.kt`
/// (claim `picture`) - but platform-sdk-swift `Users.swift` and
/// platform-sdk-react `schemas/auth.ts` read `profile_picture` for the same
/// field. The 3 official SDKs diverge from each other here; [profilePicture]
/// tries `picture` first and falls back to `profile_picture` (not a single
/// "correct" choice - it's a fallback for the two observed variants).
class YouVersionIdentity {
  YouVersionIdentity({
    required this.sub,
    required this.yvpId,
    this.email,
    this.name,
    this.profilePicture,
  });

  factory YouVersionIdentity.fromClaims(Map<String, dynamic> claims) {
    return YouVersionIdentity(
      sub: claims['sub'] as String,
      yvpId: claims['yvp_id'] as String? ?? claims['sub'] as String,
      email: claims['email'] as String?,
      name: claims['name'] as String?,
      profilePicture: claims['picture'] as String? ?? claims['profile_picture'] as String?,
    );
  }

  /// Stable user identifier (identical to [yvpId]).
  final String sub;

  /// Stable primary key of the user on the YouVersion Platform.
  final String yvpId;

  /// Declared email - NOT verified, see the class-level warning.
  final String? email;

  final String? name;
  final String? profilePicture;
}
