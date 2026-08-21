# Sign-In no Flutter (esqueleto)

`youversion_platform` não abre navegador nem captura deep link - só monta a
URL e troca o código por token. Num app Flutter, o app fica responsável por:

```dart
import 'package:url_launcher/url_launcher.dart';
import 'package:youversion_platform/youversion_platform.dart';

final signIn = YouVersionSignIn(
  appKey: 'sua-app-key',
  redirectUri: Uri.parse('https://seu-app.com/auth/callback'),
);

Future<void> iniciarLogin() async {
  final request = signIn.buildAuthorizationUrl();
  // guarde request.codeVerifier/state/nonce em memória (ex.: Riverpod state)
  await launchUrl(request.authorizationUrl, mode: LaunchMode.externalApplication);
}

// Na rota/tela que recebe o deep link de volta (ex.: GoRoute '/auth/callback'):
Future<void> aoReceberCallback(Uri callbackUri, PkceAuthorizationRequest request) async {
  final token = await signIn.exchangeCode(
    code: callbackUri.queryParameters['code']!,
    codeVerifier: request.codeVerifier,
    receivedState: callbackUri.queryParameters['state'],
    expectedState: request.state,
    expectedNonce: request.nonce,
  );
  final identity = signIn.decodeIdentity(token.idToken!);
  // persista token/identity no seu storage seguro
}
```

Mesma separação já usada no Symmetris entre `ExternalOAuthService` (app,
lança navegador/captura deep link) e `IExternalOAuthProvider` (protocolo).
