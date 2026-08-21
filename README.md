# youversion_platform

Cliente Dart não-oficial para as [YouVersion Platform APIs](https://developers.youversion.com):
Content (Bíblias), Sign-In (OAuth Authorization Code + PKCE) e Data Exchange
(sincronização de highlights).

Pacote Dart puro (sem dependência de Flutter) - só monta URLs, faz PKCE,
troca/decodifica tokens e chama a API. Não abre navegador nem captura deep
link de volta: isso fica por conta do app consumidor (`url_launcher` + rota
de callback, no caso de um app Flutter).

Não afiliado, endossado ou mantido pela YouVersion/Life.Church.

## Content API

```dart
final content = YouVersionContentClient(appKey: 'sua-app-key');

final biblias = await content.listBibles(languageRanges: ['pt', 'en']);

final trecho = await content.getPassage(
  bibleId: biblias.first.id,
  passageId: 'JHN.3.16',
);

print(trecho.content);
```

## Sign-In (OAuth PKCE)

```dart
final signIn = YouVersionSignIn(
  appKey: 'sua-app-key',
  redirectUri: Uri.parse('https://seu-app.com/auth/callback'),
);

// 1. Monte a URL e guarde codeVerifier/state/nonce (sessão/memória).
final request = signIn.buildAuthorizationUrl(
  permissions: {YouVersionPermission.profile, YouVersionPermission.email},
);
// abra request.authorizationUrl no navegador (url_launcher, por ex.)

// 2. Quando o redirect voltar com ?code=...&state=...:
final token = await signIn.exchangeCode(
  code: codeRecebido,
  codeVerifier: request.codeVerifier,
  receivedState: stateRecebido,
  expectedState: request.state,
  expectedNonce: request.nonce,
);

// 3. Identidade vem do id_token (não confiável quanto a e-mail verificado -
//    a YouVersion não emite claim `email_verified`).
final identity = signIn.decodeIdentity(token.idToken!);
print(identity.name);
```

Renovando o access token depois:

```dart
final novoToken = await signIn.refreshToken(token.refreshToken);
// novoToken.idToken vem nulo - reuse o idToken da troca inicial se precisar
// decodificar a identidade de novo.
```

## Data Exchange (highlights)

```dart
final dataExchange = YouVersionDataExchangeClient(appKey: 'sua-app-key');

final token = await dataExchange.createToken(userAccessToken: token.accessToken);
final approvalUrl = dataExchange.buildApprovalUrl(token);
// abra approvalUrl no navegador - o usuário aprova e o navegador redireciona
// pro callback URL configurado no console de desenvolvedor da YouVersion.
```

## Segurança - e-mail não verificado

A Sign-In API da YouVersion não emite claim `email_verified`. Nunca use
`YouVersionIdentity.email` para vincular/mesclar automaticamente com uma
conta existente por igualdade de string sem alguma confirmação adicional
(o mesmo cuidado que qualquer provedor OAuth sem essa garantia exige, ex.:
Microsoft, Spotify).

## Fonte dos contratos de API

Os endpoints e formatos usados aqui foram validados contra o código-fonte do
[SDK oficial Kotlin](https://github.com/youversion/platform-sdk-kotlin), não
só contra a documentação pública - alguns detalhes (o path com hífen de
`/data-exchange`, o claim `picture` em vez de `profile_picture`, `versionId`
sendo numérico) só ficaram claros lendo o código.

## Licença

MIT.
