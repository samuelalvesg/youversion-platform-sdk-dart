## Unreleased

- `YouVersionHighlightsSyncEngine`: a `404` on `deleteHighlight` (the
  highlight was already removed server-side - another device, or an
  earlier attempt of the same retry actually landed) now counts as a
  successful removal instead of being retried with backoff forever.
  Previously fell into the same generic-failure path as any other
  non-`403` error, so a delete against an already-gone highlight could
  never "succeed" and retried indefinitely.

- Added `YouVersionHighlightsSyncEngine` - an in-memory, offline-aware
  sync layer on top of `YouVersionHighlightsClient`: optimistic local
  writes, a retry queue with exponential backoff (`1s, 2s, 4s, 8s, 16s,
  30s`, capped), account-wide permission-refusal (`403`) handling that
  drops the affected queue instead of wedging it (and triggers a reload
  of the affected chapters), per-chapter load throttling (5 minutes,
  configurable) + in-flight-load deduplication, and a `reset()` for
  session-scoped invalidation (call on sign-out/account-switch - no
  in-flight retry/load from before that call is applied afterward).
  Ported from platform-sdk-kotlin's `BibleHighlightsRepository`/
  `BibleHighlightCache`, adapted to pure Dart (no `Mutex`/`StateFlow` -
  see the class doc comment and `docs/DECISIONS.md`). In-memory only,
  cleared on `close()` - complements, doesn't replace,
  `youversion_platform_reader`'s `PendingHighlightQueue` (which persists
  across app restarts while signed out - a different concern this engine
  doesn't attempt).

- `YouVersionContentClient`/`YouVersionLanguagesClient`: added in-flight
  request deduplication + an in-memory (not persistent) result cache -
  two concurrent identical calls (e.g. `getBible(206)` from two widgets
  at once) now share one HTTP request instead of firing two, and a
  completed result is served from memory on a later call with the same
  parameters. Applies to `getBible`/`getIndex`/`getPassage`/`getBook`/
  `getChapter`/`getVerse`/`listBibles`/`listBooks`/`listChapters`/
  `listVerses` on `YouVersionContentClient`, and `getLanguage`/
  `listLanguages` on `YouVersionLanguagesClient`. Cleared on `close()`,
  never touches disk - not the "offline content cache" this package
  deliberately doesn't implement (host app's job, see
  `docs/DECISIONS.md`). Matches the pattern in platform-sdk-kotlin's
  `BibleVersionRepository`/`BibleChapterRepository`.

- Added `OAuthLoopbackServer` - a temporary local HTTP server for the
  RFC 8252 §7.3 loopback-interface desktop sign-in flow (open the system
  browser, catch the redirect on `http://127.0.0.1:<port>`, no
  custom-scheme deep link needed). `dart:io`-based, conditionally
  exported (a web stub stands in when `dart:io` isn't available, so
  depending on this package still compiles for Flutter Web). See
  `docs/DECISIONS.md`.

- Added `YouVersionErrorReason.rateLimited` (`429`), applied universally
  across every client ahead of any endpoint-specific `reasonForStatus` -
  see `docs/DECISIONS.md`.
- `YouVersionContentClient`/`YouVersionLanguagesClient`/
  `YouVersionOrganizationsClient` now map `401` (missing/invalid App Key)
  to `YouVersionErrorReason.missingAuthentication`, confirmed live -
  previously these 3 had no `reasonForStatus` at all.
- `getPassage`'s doc comment now states `format` is `'html'`/`'text'` only
  - confirmed live against the API; `'json'` (which appeared as a raw
    string in Kotlin's own URL-building tests) 404s.
- Added `YouVersionSignIn.resolveCallback` + `YouVersionHttpClient.getRedirectLocation`.
  **Real, confirmed-live gap**: this package's Sign-In doc comment
  previously assumed the `/auth/authorize` redirect always lands with
  `code` directly in the query string - wrong for at least some App Key
  configurations, which redirect with only `state`/`granted_permissions`
  first and require an extra `/auth/callback` hop (matches what Kotlin's
  `UsersEndpoints.kt` always does internally via `obtainLocation`/
  `obtainCode`, which this package's public API never exposed). Not
  usable on Flutter Web - browsers don't expose a cross-origin manual
  redirect's `Location` header to JS at all. See `docs/DECISIONS.md`.
- **Fixed a real bug** (confirmed live, crashed `exchangeCode` mid-flow):
  `YouVersionToken.fromJson` cast `expires_in` straight to `int`, but the
  server actually sends it as a string. Now accepts `int`/`String`/`num`.
- **Fixed a real bug** (confirmed live, crashed `createHighlight`/
  `listHighlights`): `Highlight.id` was cast straight to `String`, but the
  server can omit it entirely - matches Kotlin's own `id: String? = null`.
  Now `String?`. See `docs/DECISIONS.md`.
- Added `YouVersionException.retryAfter` (`Duration?`), parsed from a
  `429`'s `Retry-After` header (confirmed live, an integer-seconds string
  - `600` = 10 minutes). Lets callers show a real wait time / disable a
  retry button instead of inviting another guaranteed-to-fail request.

## 0.2.0

Gap-closing release: contracts cross-validated against the source code of
all 4 official SDKs (Kotlin, Swift, React, React Native/Expo), not just
public documentation. See `docs/DECISIONS.md` at the repo root for the
methodology and confirmed inter-SDK discrepancies.

- Added Languages API (`YouVersionLanguagesClient`).
- Added Organizations API (`YouVersionOrganizationsClient`).
- Added VOTD (Verse of the Day) API (`YouVersionVotdClient`).
- Added Highlights direct CRUD API (`YouVersionHighlightsClient`), distinct
  from Data Exchange's consent-only flow.
- Added `YouVersionContentClient.getIndex` (full book/chapter/verse tree in
  one call, includes `textDirection`), plus single-item `getBook`,
  `getChapter`, `getVerse`.
- List endpoints now return `YouVersionCollection<T>` (`data`,
  `nextPageToken`, `totalSize`) instead of a bare `List<T>`, so pagination
  is actually usable.
- `Bible`/`BibleBook`/`BibleChapter` gained several previously-missing
  fields (`textDirection`, `copyright`, `chapters`, `intro`, etc.).
- `YouVersionPermission` gained `bibles`, `votd`, `demographics`,
  `bibleActivity`.
- `YouVersionSignIn`/`YouVersionDataExchangeClient` now parse
  `granted_permissions` from the OAuth/consent callback URL.
- `YouVersionIdentity.profilePicture` now falls back between the `picture`
  and `profile_picture` JWT claims (official SDKs disagree on the name).
- Added `X-YVP-Installation-Id`/`X-YVP-Sdk` headers and a request timeout
  to every client.
- `YouVersionException` gained a `reason` (`YouVersionErrorReason`)
  classifying failures the way the official SDKs do, instead of a flat
  status code.
- **Breaking**: package renamed from `youversion_platform` to
  `youversion_platform_core`; moved into a `packages/` monorepo layout;
  license changed from MIT to Apache 2.0.

## 0.1.0

- First release: Content API (bibles/passages/books/chapters/verses),
  Sign-In (Authorization Code + PKCE), and Data Exchange (highlights).
