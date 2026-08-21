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
