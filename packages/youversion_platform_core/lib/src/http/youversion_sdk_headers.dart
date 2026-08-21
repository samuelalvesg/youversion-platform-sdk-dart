/// Package version reported in the `X-YVP-Sdk` header - keep in sync with
/// `pubspec.yaml` on every release.
const String youVersionSdkVersion = '0.2.0';

/// Builds the headers common to every App Key-authenticated call, the
/// same ones the official SDKs always send (`x-yvp-sdk`,
/// `x-yvp-installation-id` - see `PlatformCoreKoinModules.kt` in the
/// Kotlin SDK, `defaultRequestHeaders()`).
///
/// [installationId] is optional because this package is storage-agnostic -
/// it doesn't persist anything on its own. Generate a UUID once in the
/// consuming app, store it wherever makes sense (e.g.
/// `shared_preferences`) and pass the same value to every client instance
/// to keep calls consistent.
Map<String, String> youVersionSdkHeaders({
  required String appKey,
  String? installationId,
}) {
  return {
    'X-YVP-App-Key': appKey,
    'X-YVP-Sdk': 'DartSDK=$youVersionSdkVersion',
    if (installationId != null) 'X-YVP-Installation-Id': installationId,
  };
}
