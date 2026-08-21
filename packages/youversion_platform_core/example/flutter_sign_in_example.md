# Sign-In on Flutter (skeleton)

`youversion_platform_core` doesn't open a browser or capture the deep link - it
only builds the URL and exchanges the code for a token. In a Flutter app, the
app is responsible for:

```dart
import 'package:url_launcher/url_launcher.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

final signIn = YouVersionSignIn(
  appKey: 'your-app-key',
  redirectUri: Uri.parse('https://your-app.com/auth/callback'),
);

Future<void> startLogin() async {
  final request = signIn.buildAuthorizationUrl();
  // store request.codeVerifier/state/nonce in memory (e.g. Riverpod state)
  await launchUrl(request.authorizationUrl, mode: LaunchMode.externalApplication);
}

// In the route/screen that receives the deep link back (e.g. GoRoute '/auth/callback'):
Future<void> onCallbackReceived(Uri callbackUri, PkceAuthorizationRequest request) async {
  final token = await signIn.exchangeCode(
    code: callbackUri.queryParameters['code']!,
    codeVerifier: request.codeVerifier,
    receivedState: callbackUri.queryParameters['state'],
    expectedState: request.state,
    expectedNonce: request.nonce,
  );
  final identity = signIn.decodeIdentity(token.idToken!);
  // persist token/identity in your secure storage
}
```

Same separation already used in Symmetris between `ExternalOAuthService` (app,
launches the browser/captures the deep link) and `IExternalOAuthProvider` (protocol).
