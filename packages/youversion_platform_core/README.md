# youversion_platform_core

Unofficial Dart client for the [YouVersion Platform APIs](https://developers.youversion.com):
Content (Bibles), Sign-In (OAuth Authorization Code + PKCE), Data Exchange,
Highlights, Languages, Organizations, and VOTD (Verse of the Day).

Pure Dart package (no Flutter dependency) - it only builds URLs, performs PKCE,
exchanges/decodes tokens, and calls the API. It doesn't open a browser or capture
the deep link back: that's the consuming app's responsibility (`url_launcher` +
a callback route, in the case of a Flutter app).

Equivalent to the `platform-core` module of the official SDKs (Kotlin, Swift,
React, React Native/Expo) - without their `platform-ui`/`platform-reader`
layers (native Bible-reading UI), which are out of scope for this package.

Not affiliated with, endorsed by, or maintained by YouVersion/Life.Church.

Repo: <https://github.com/samuelalvesg/youversion-platform-sdk-dart>

## Installation

Inside this monorepo, the publishable package lives at `packages/youversion_platform_core/`.

```yaml
dependencies:
  youversion_platform_core: ^0.2.0
```

## Content API

```dart
final content = YouVersionContentClient(appKey: 'your-app-key');

final bibles = await content.listBibles(languageRanges: ['pt', 'en']);

final passage = await content.getPassage(
  bibleId: bibles.data.first.id,
  passageId: 'JHN.3.16',
);

print(passage.content);
```

`listBibles`/future list endpoints return `YouVersionCollection<T>` (`data`,
`nextPageToken`, `totalSize`) - paginate by repeating the call with
`pageToken: result.nextPageToken` until `hasNextPage` is `false`.

Full book → chapter → verse tree (includes `textDirection`, useful
for RTL Bibles) in a single call:

```dart
final index = await content.getIndex(bibles.data.first.id);
print(index.textDirection); // 'ltr' or 'rtl'
```

## Sign-In (OAuth PKCE)

```dart
final signIn = YouVersionSignIn(
  appKey: 'your-app-key',
  redirectUri: Uri.parse('https://your-app.com/auth/callback'),
);

// 1. Build the URL and store codeVerifier/state/nonce (session/memory).
final request = signIn.buildAuthorizationUrl(
  permissions: {YouVersionPermission.profile, YouVersionPermission.email},
);
// open request.authorizationUrl in the browser (e.g. via url_launcher)

// 2. When the redirect comes back with ?code=...&state=...:
final token = await signIn.exchangeCode(
  code: receivedCode,
  codeVerifier: request.codeVerifier,
  receivedState: receivedState,
  expectedState: request.state,
  expectedNonce: request.nonce,
  grantedPermissions: YouVersionSignIn.parseGrantedPermissions(callbackUri),
);

// 3. Identity comes from the id_token (not reliable for verified email -
//    YouVersion does not issue an `email_verified` claim).
final identity = signIn.decodeIdentity(token.idToken!);
print(identity.name);
```

Refreshing the access token later:

```dart
final newToken = await signIn.refreshToken(token.refreshToken);
// newToken.idToken comes back null - reuse the idToken from the initial
// exchange if you need to decode the identity again.
```

## Highlights (direct CRUD)

Requires the user's access token with the `highlights` permission granted.
Distinct from Data Exchange below (which only creates a one-off consent
token) - this is the real CRUD for highlights.

```dart
final highlights = YouVersionHighlightsClient(appKey: 'your-app-key');

final userHighlights = await highlights.listHighlights(
  userAccessToken: token.accessToken,
  bibleId: 111,
  passageId: 'MAT.1.1',
);

await highlights.createHighlight(
  userAccessToken: token.accessToken,
  bibleId: 111,
  passageId: 'MAT.1.1',
  color: HighlightColors.yellow,
);

await highlights.deleteHighlight(
  userAccessToken: token.accessToken,
  bibleId: 111,
  passageId: 'MAT.1.1',
);
```

`HighlightColors` is the fixed client-side palette from the official SDKs
(not an API endpoint).

## Data Exchange (one-off consent to sync highlights)

```dart
final dataExchange = YouVersionDataExchangeClient(appKey: 'your-app-key');

final deToken = await dataExchange.createToken(userAccessToken: token.accessToken);
final approvalUrl = dataExchange.buildApprovalUrl(deToken);
// open approvalUrl in the browser - the user approves and the browser redirects
// to the callback URL configured in the YouVersion developer console.

// in the callback:
final result = dataExchange.parseCallback(callbackUri);
if (result.isGranted) { /* ... */ }
```

**Security note**: the consent redirect is fire-and-forget - if the logged-in
user changes between `createToken` and `parseCallback`, the grant could be
applied to the wrong user. Record which `sub` initiated the flow
(`YouVersionSignIn.decodeIdentity`) and compare it against the logged-in user
at the time of the callback before trusting the result.

## Languages

```dart
final languages = YouVersionLanguagesClient(appKey: 'your-app-key');
final result = await languages.listLanguages(country: 'BR');
```

## Organizations

```dart
final organizations = YouVersionOrganizationsClient(appKey: 'your-app-key');
final org = await organizations.getOrganization(bible.organizationId!);
```

## VOTD (Verse of the Day)

```dart
final votd = YouVersionVotdClient(appKey: 'your-app-key');
final today = await votd.getDay(DateTime.now().dayOfYear);
```

## Security - unverified email

YouVersion's Sign-In API does not issue an `email_verified` claim. Never use
`YouVersionIdentity.email` to automatically link/merge with an existing
account by string equality without some additional confirmation (the same
caution that any OAuth provider without this guarantee requires, e.g.:
Microsoft, Spotify).

## Errors

Every call throws `YouVersionException` with a `reason`
(`YouVersionErrorReason`: `missingAuthentication`, `notPermitted`,
`cannotDownload`, `invalidResponse`, `unknown`) - the same HTTP status
means different things on different endpoints (e.g.: `401` on
Highlights means "no authentication", on Data Exchange it means "token
denied"), so prefer checking `reason` over the raw `statusCode`.

## API contract sources

The endpoints and formats used here were validated against the source code
of the official SDKs, not just the public documentation:

| Surface        | Official source validated |
|-----------------|--------------------------|
| Content/Bibles | platform-sdk-kotlin `bibles/api/BiblesEndpoints.kt` |
| Sign-In        | platform-sdk-kotlin `users/api/UsersEndpoints.kt`, cross-checked with platform-sdk-swift `Users.swift`, platform-sdk-react `Users.ts` |
| Data Exchange  | platform-sdk-kotlin `dataexchange/api/DataExchangeEndpoints.kt`, platform-sdk-react `data-exchange.ts` |
| Highlights     | platform-sdk-kotlin `highlights/api/HighlightsEndpoints.kt`, cross-checked with platform-sdk-swift `Highlights.swift`, platform-sdk-react `highlights.ts` |
| Languages      | platform-sdk-kotlin `languages/api/LanguagesEndpoints.kt` |
| Organizations  | platform-sdk-kotlin `organizations/api/OrganizationsEndpoints.kt` |
| VOTD           | platform-sdk-kotlin `votd/api/VotdEndpoints.kt` |

Where the official SDKs diverge from each other (e.g.: the `picture` vs
`profile_picture` claim in the `id_token` - Kotlin uses one, Swift/React use
the other), the package applies a fallback for both variants instead of
arbitrarily picking one, and this is documented in the doc comment of the
corresponding class.

## License

Apache 2.0 - see [`LICENSE`](LICENSE).
