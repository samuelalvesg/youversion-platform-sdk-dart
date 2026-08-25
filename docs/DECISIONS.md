# Decisions log

Durable record of non-obvious decisions made while building this monorepo,
for future contributors (human or AI) who weren't in the original
conversation. Language: English (this repo targets pub.dev, an
international audience) - see `CONTRIBUTING.md` for the reasoning.

## Repo layout

- **Monorepo with `packages/`**, mirroring the official `platform-sdk-react`
  layout (single repo, multiple published packages under `packages/`).
  `packages/youversion_platform_core/` is the first and, as of this
  writing, only package - equivalent to the official `platform-core`
  module. If UI/reader layers are ever built, they belong as siblings:
  `packages/youversion_platform_ui/`, `packages/youversion_platform_reader/`.
- **Package name**: `youversion_platform_core` (not `youversion_platform`,
  the name used during initial v0.1.0 development before this decision).
  Verified available on pub.dev before renaming. Mirrors the official
  `platform-core` module name so a future `_ui`/`_reader` package naming
  scheme stays consistent.
- **Monorepo, not one repo per package**: considered splitting `core`/`ui`/
  `reader` into separate repos (as this author's other Flutter package,
  `pillar_ui`, does - one repo, `pubspec.yaml` at repo root, consumed
  elsewhere via a plain `git:` dependency with no `path:`). Decided against
  it: pub.dev publishing is per-package regardless of repo layout, so
  nothing is lost by keeping one repo; a monorepo keeps `docs/DECISIONS.md`
  (cross-SDK discrepancies, gap-sweep history) in one place instead of
  scattered across repos, and a future `_ui`/`_reader` package can depend
  on `_core` via a local `path:` dependency instead of duplicating types.
  Consuming this package via `git:` before it's on pub.dev (same pattern as
  `pillar_ui`) just needs an extra `path:` key inside the `git:` block,
  which `pub` supports natively for subdirectory packages:
  ```yaml
  youversion_platform_core:
    git:
      url: https://github.com/samuelalvesg/youversion-platform-sdk-dart.git
      path: packages/youversion_platform_core
  ```
  Would only reconsider separate repos if different packages ever needed
  different collaborator/permission scopes - not the case here.

## `youversion_platform_ui` / `youversion_platform_reader` (planned, not yet built)

Investigated (2026-08-21) via 5 parallel agents: the UI/reader modules of all 4
official SDKs, plus this author's own established Flutter conventions (the
Symmetris app and its `pillar_ui`/`pillar_core`/`pillar_http` packages).

- **3 packages, not 2**: Kotlin and Swift both split `platform-ui` (standalone
  components) from `platform-reader` (full chapter-reading screen, depends on
  `-ui`), each their own build target/product with an API-stability baseline.
  React and React Native/Expo instead merge both into a single `ui` package
  (the "reader" is just one compound component/widget inside it, e.g. React's
  `BibleReader` in `packages/ui/src/components/bible-reader.tsx`). Chose the
  3-package split (`youversion_platform_ui`, `youversion_platform_reader`,
  siblings of `_core` under `packages/`) - it was already the stated intent
  earlier in this file, and it lets an app that only wants a sign-in
  button/verse card/VOTD widget avoid pulling in the full reading-screen
  dependency tree.
- **Confirmed this does not complicate state-management integration**
  (a concern raised before committing to it): neither package will own a
  Riverpod/Provider/Bloc dependency or expose its own state-management
  primitive. Widgets take data and callbacks as constructor parameters - the
  exact pattern this author's own `pillar_ui` package already uses in the
  Symmetris app (e.g. its `ErrorContainerWidget` takes no provider, the app's
  own Riverpod providers own all state and pass data down). A consuming app
  wires up `_ui`/`_reader` widgets from its own providers either way,
  regardless of whether they ship as one package or three - splitting them
  doesn't add an extra integration surface, it only affects how the SDK
  itself is packaged/versioned.
- **Storage-agnostic** (same principle as `_core`'s `installationId`): the
  reader needs to persist last-read reference, font/theme settings, and a
  pending-highlight-request queue (a real feature worth porting - if a user
  taps "highlight" while signed out or before granting the `highlights`
  permission, Kotlin/RN-Expo queue the request and replay it once
  sign-in/consent completes, surviving process death). None of that goes
  through a bundled storage engine - the reader package will define a small
  `YouVersionReaderStorage` interface and let the host app implement it.
- **Fonts by injection, not bundled**: the official SDKs ship a proprietary
  "Untitled Serif" display font (+ "Aktiv Grotesk"/Inter for UI chrome).
  Not bundling third-party font files/licenses into this package - accept a
  font family/`TextStyle` via theme injection instead (mirrors Kotlin's
  `FontDefinitionProvider` escape hatch), falling back to the system font.
- **Implemented (2026-08-21)**: both packages built per the plan above.
  `youversion_platform_ui` (theme + 10 widgets) and
  `youversion_platform_reader` (`BibleReader`, `ChapterNavigation`,
  `PendingHighlightQueue`, `ReaderFontSettings`/`ReaderSettingsStorage`,
  `YouVersionReaderStorage`, `ReferencesScreen`, `FontSettingsSheet`) -
  `flutter analyze` clean (only the expected `path:`-dependency warning,
  same as any pre-pub.dev monorepo package) and `flutter test` green (2
  widget tests in `_ui`, 8 unit tests in `_reader`) in both. One real bug
  caught by `flutter analyze` during this pass: `ReaderColorScheme`'s
  `highlightBorder` was constructed from a 10-hex-digit literal
  (`0xFF00000029`, a typo - `Color()` only takes 8 hex digits/`0xAARRGGBB`),
  fixed to `0x29000000`.
- **Repo name**: `youversion-platform-sdk-dart` - kept generic/monorepo-shaped
  on purpose, matching how the official repos are named differently from
  the packages they contain (e.g. repo `platform-sdk-react` ships npm
  package `@youversion/platform-core`).
- **License**: Apache 2.0 (not MIT) - matches all 4 official SDKs
  (Kotlin, Swift, React, React Native/Expo). Apache 2.0's explicit patent
  grant + termination-on-litigation clause is the deciding factor over
  MIT's simplicity, given this package closely mirrors a third party's API
  contract.

## Design principle: pure Dart, no Flutter dependency

Mirrors how YouVersion's own JS "core" SDK works in browser/Node/serverless
context, with React/React Native as separate UI layers on top. This
package never launches a browser/webview and never captures a deep link
itself - that's the consuming app's job (Flutter: `url_launcher` + a
deep-link route). This keeps the package usable from plain Dart
(CLI/server), not just Flutter, and keeps parity with the "protocol
client" vs "UI flow" split used elsewhere in this author's other projects.

## Gap-analysis methodology (v0.2.0)

v0.1.0 was built primarily from `developers.youversion.com` documentation.
Before extending it, 4 parallel investigations cross-checked the actual
source code of all 4 official SDKs (via `gh api`, reading real endpoint
files - not just docs) against this package:

- `youversion/platform-sdk-kotlin` (fully open source, used as the primary
  source of truth for exact paths/field names - the only SDK where all
  endpoint implementations are actually public).
- `youversion/platform-sdk-swift` (cross-check).
- `youversion/platform-sdk-react` (cross-check, monorepo with typed
  schemas - useful for confirming field names/types).
- `youversion/platform-sdk-reactnative-expo` (dead end as a direct source -
  it only consumes the private npm package `@youversion/platform-core`,
  no endpoint code in the repo itself; used Kotlin as ground truth instead).

Where the official SDKs **disagree with each other**, this package does
not arbitrarily pick one - it either implements a fallback covering both
observed variants, or documents the discrepancy in the relevant doc
comment so a future reader isn't confused by our own code changing
behavior without explanation.

### Confirmed inter-SDK discrepancies (as of 2026-08-21)

- **Avatar/profile picture JWT claim**: Kotlin reads `picture`, Swift and
  React both read `profile_picture`. This package's `YouVersionIdentity`
  tries `picture` first, falls back to `profile_picture`. Not resolved
  upstream - if you ever get a real ID token and can confirm which one the
  server actually sends, please update this note and simplify the code.
- **`Language.default_bible_version_id`** (not `default_bible_id`, an
  earlier assumption from docs alone that source-reading corrected).
- **`HighlightColor` is not a remote resource** - despite appearing as a
  typed entity in the public TypeScript-types documentation page, no
  official SDK calls a network endpoint for it. It's a fixed 5-color
  client-side palette, hardcoded identically across SDKs. Implemented here
  as `HighlightColors` (a const-only class), not a model with `fromJson`.
- **No functional `/v1/users/me`-style endpoint exists** in any official
  SDK. `UsersApi.userInfo()` is a literal `TODO` in the Kotlin source;
  Swift has no such call at all. All user identity in this package comes
  from decoding the Sign-In `id_token` locally - this is intentional
  parity with upstream, not a missing feature.

## 2026-08-21 follow-up gap sweep (no action taken)

A second round, using cheaper/faster (Haiku) agents, re-checked a handful of
loose ends the first sweep had flagged but not confirmed, plus did a general
"did we miss a whole module" pass and a "did anything change since we
validated" pass. Result: no real gaps found, package stays as-is.

- `License`, `Video`, `AppSummary` TypeScript schemas (platform-sdk-react
  `packages/core/src/schemas/{license,video,app}.ts`): all three are
  orphaned schemas - defined and exported, but never imported by any
  function that makes an HTTP call. No Kotlin/Swift equivalent either.
  `license_id` (already a filter param on `listBibles`) is just a query
  string value, not a resource with its own endpoint. Not a gap.
- `Font`/`FontVariant`/`FontSource` schema: a real endpoint does exist -
  `GET /v1/fonts/{id}/stylesheet` (confirmed via an ADR in the React repo,
  "Adopt Untitled Serif via Fonts API") - but it returns a CSS stylesheet,
  not JSON, `{id}` is hardcoded to `1` (no font-discovery/listing endpoint
  exists), and it's consumed by `packages/ui` to inject a `<link>` tag for
  one specific webfont used in their reading UI. This is a UI-layer
  webfont-loading concern, not Bible-content/protocol data - out of scope
  for this package by the same reasoning as `platform-ui`/`platform-reader`
  being out of scope entirely.
- `User{avatar_url, first_name, last_name, id}` schema (React,
  `schemas/user.ts`): confirmed orphaned - exported but never imported
  anywhere, and no `/v1/users/*` REST endpoint exists in any of the 4
  official SDKs. Reconfirms all identity in this package correctly comes
  from decoding the `id_token` locally.
- Full re-sweep of `platform-core`'s module list (Kotlin, cross-checked
  against Swift/React top-level API files): the 7 modules already
  implemented (Content/Bibles, Sign-In, Data Exchange, Highlights,
  Languages, Organizations, VOTD) are the complete set. No 8th module
  exists anywhere.
- Drift check: re-read commit history for every official-SDK file cited in
  this package's doc comments. Most recent relevant commit was 2026-08-05,
  well before the 2026-08-21 validation date - nothing changed underneath
  us since v0.2.0 was implemented.

## i18n of `_ui`/`_reader` widget strings (2026-08-24)

Cloned the 3 SDKs with public source (`platform-sdk-kotlin`,
`platform-sdk-react`, `platform-sdk-reactnative-expo`) into
`.references-repo/` (gitignored) as a standing local reference, per the same
gap-analysis discipline as the v0.2.0 sweep above - `git clone --depth 1`
each, re-clone/pull when re-validating.

- **Mechanism**: Flutter's official `gen-l10n` (ARB source files +
  generated `AppLocalizations`-style class), not `intl`'s runtime message
  lookup or a third-party package - the idiomatic Dart/Flutter approach,
  and consistent with this package already being Flutter-only (unlike
  `_core`, which stays pure Dart). React's sister package uses `i18next`,
  Kotlin/Swift use platform-native `strings.xml`/`Localizable.strings` -
  none of those are portable to Dart, so "align with them" (per the React
  repo's own `AGENTS.md`) means matching their *coverage*, not their
  tooling.
- **Two independent generated classes**, `YouVersionUiLocalizations` and
  `YouVersionReaderLocalizations` (`output-class` in each package's
  `l10n.yaml`), not one shared class - an app can depend on both packages
  at once and must register both delegates without a name collision.
  Generated output is committed to `lib/src/l10n/` (`synthetic-package:
  false`) rather than left in `.dart_tool/` - a consumer of a *dependency*
  package doesn't run `flutter gen-l10n` for it, so the generated code has
  to ship in the package itself, same reasoning as any Flutter package that
  ships its own l10n (e.g. `flutter_localizations` itself).
- **Zero-config fallback preserved**: widgets call a small hand-written
  `youVersionUiStringsOf(context)` / `youVersionReaderStringsOf(context)`
  wrapper (not the generated class's own `.of(context)`, which asserts
  non-null and throws if the host never registered the delegate) that falls
  back to the bundled `...LocalizationsEn()` instance when the delegate
  isn't registered. Mirrors the existing `BibleTextTheme.of`/
  `ReaderColorScheme.of` fallback-to-default pattern - every widget in
  these packages works with zero required host configuration, l10n
  included; registering the delegate is opt-in.
- **Translation reuse, not fabrication**: only reused a string for a locale
  when `@youversion/platform-react-ui`'s locale file
  (`packages/ui/src/i18n/locales/*.json`, human-reviewed, 14 locales:
  `en af ar cs cy de es fr ko no pt tr vi zh`) has an exact or near-exact
  semantic match to our string - reused that translation verbatim (copy
  button, share button, cancel, close, sign out, search hints, the
  pending-highlights sign-out warning). Two of ours were reworded slightly
  to align with React's canonical phrasing so the reuse is a real match
  ("Remove highlight" to "Clear highlight"; the unsynced-highlights sign-out
  message now matches React's wording, including its trailing question).
  Did **not** invent translations for strings with no upstream match
  (sign-in-failed dialog copy, "Font size"/"Line spacing"/"Dark mode",
  "Bible"/"Font settings" fallback labels, "Intro" chip, "Not now",
  "Search translations", "Sign out?" title) - those ship English-only;
  `gen-l10n` falls back to the English template for any locale missing a
  key, so nothing crashes, it's just not translated yet. A future pass with
  a real translator (or a confirmed upstream match) can fill these in
  without any structural change.
- **`fr.json` is a partial locale upstream** (missing several of the keys
  we do reuse, e.g. `closeAriaLabel`, `genericCancel`) - not our gap, just
  passed through as-is (falls back to English for those specific strings in
  `fr` only).
- Brand name ("YouVersion") is never routed through l10n - it's a literal
  Dart constant interpolated into `signInWithYouVersionLabel`, same as
  React templates it via `{{brandName}}` rather than translating it.

## a11y/RTL gap sweep (2026-08-24, same day as the i18n work above)

3 cheap/fast (Haiku) agents, one per cloned reference repo, each checking
our new i18n/a11y work for gaps against that SDK's own accessibility and
RTL patterns - same "use cheap agents for a wide, shallow sweep" approach
as the 2026-08-21 follow-up sweep. Findings, verified before acting on
them (Haiku findings aren't always accurate - two were checked directly
against source and one claim didn't hold up, see below):

- **Verified and acted on**: React's `highlightColorsAriaLabel` ("Highlight
  colors" - group label for the swatch row) had a full 14-locale match we
  hadn't reused yet. Added as `highlightColorsLabel`, wrapping the swatch
  `Row` in `Semantics(container: true, label: ...)`.
- **Checked, no gap found**: React's report of "most interactive elements
  lack screen-reader labels" doesn't hold up under Flutter's own
  accessibility model - `IconButton.tooltip` already doubles as the
  Semantics label (unlike web, where `title` and `aria-label` are
  separate), and `ListTile.selected` already forwards to
  `Semantics(selected: ...)` (used by both `BibleVersionPicker` and
  `BibleLanguagePicker` already). React/RN-Expo's `role="dialog"` /
  live-region suggestions are also handled for free by `showDialog` +
  `AlertDialog`, which Flutter already announces on open. Not every
  web/RN a11y pattern has a missing Flutter equivalent - some are just
  built into the widgets we're already using.
- **Not acted on, logged instead** (real feature gaps, not a11y bugs -
  see `BACKLOG.md`): Kotlin's reader font-settings sheet has a 7-swatch
  theme picker and dedicated smaller/bigger buttons with text labels that
  our `FontSettingsSheet` doesn't have; `BibleTextView` is a minimal
  regex-based HTML stripper with no RTL-aware footnote/verse-number/
  words-of-Christ handling, unlike Kotlin's `BibleText.kt`. Both are
  larger content-rendering/feature-parity work, out of scope for an
  i18n/a11y pass.
- **Repo drift found**: `platform-sdk-reactnative-expo` is no longer the
  "dead end, no endpoint code" repo described in the v0.2.0 gap-analysis
  section above - it now has real native UI source under
  `packages/ui/src/native/` (e.g. `bible-verse-action-sheet.tsx`), not
  just a consumer of the private npm package. Re-clone and re-check this
  repo specifically next time RN/Expo-specific patterns matter; the
  "dead end" note above is stale as of 2026-08-24.
- RTL layout depends on the host registering `supportedLocales`/
  `localizationsDelegates` (documented in each package's README) - without
  that, Flutter's ambient `Directionality` stays `ltr` regardless of
  device locale, same caveat as the strings themselves defaulting to
  English.

## `BibleTextView` real renderer + reading theme + verse tap-select (2026-08-24)

Closed the two gaps the a11y/RTL sweep above found (`BibleTextView` was a
regex stripper; `FontSettingsSheet` had no theme picker), plus the user's
own two explicit product requirements: red-letter words-of-Christ (already
confirmed by both Kotlin and React - fixed color, not theme-driven upstream
in either), and tap-a-whole-verse selection with a dashed underline (this
package's own choice - React/Kotlin both use a solid underline for the
equivalent state; no reference SDK does dashed, this came from the user's
own knowledge of the closed-source official app, not from any of the 3
cloned repos).

- **`format=json` confirmed dead, with live evidence, not just absence of
  usage**: called the real API directly (`GET
  /v1/bibles/206/passages/JHN.3.1?format=json`) - 404, "Bible passage
  JHN.3.1 for version 206 not found" - the exact same passage that returns
  200 with `format=html`. The official API docs (pasted into this session)
  confirm the real enum is `text`/`html` only; `json` never existed as a
  documented option. Kotlin's own test suite only checks that the SDK
  *sends* whatever string you pass as `format` in the URL - it never
  asserts the server accepts `json`, which is why grepping for it in
  Kotlin's source looked like weak evidence for support that doesn't
  actually exist. `youversion_platform_core`'s `getPassage` doc comment
  now states this explicitly.
- **`format=text` confirmed strictly worse than `html` for this widget's
  purposes**, also via a live call: flat string, no verse boundaries, no
  words-of-Christ, no footnotes (even with `include_notes=true`), no
  headings - the same information loss the old regex-based `BibleTextView`
  had. `html` is a strict superset. Settles that `html` + a real parser was
  the correct choice, not a detour.
- **YVDOM parser lives in `youversion_platform_ui`, not `_core`**: Kotlin
  (this repo's primary source of truth) puts this parsing in `platform-ui`,
  not `platform-core`; React puts it in its portable core package instead.
  Chose Kotlin's placement - keeps `_core` free of the new `package:html`
  dependency and free of any rendering-adjacent responsibility, consistent
  with `_core`'s existing "pure Dart, usable outside Flutter" principle
  (a YVDOM node tree has no use outside a rendering context anyway).
- **Parser verified against real API output, not just paraphrased test
  fixtures**: pulled `GET /v1/bibles/206/passages/JHN.3?format=html` (WEBUS,
  public domain, full John 3, 36 verses) and `MAT.5.3` (words-of-Christ
  split across two sibling `<div>`s by poetry-line classes `q1`/`q2`, plus
  a `.yv-n.x` cross-reference with no nested `.ft` span) live, and ran the
  parser against both before writing them into
  `test/bible_text_node_test.dart` as permanent fixtures. Confirmed the
  parser's "sticky current verse number across sibling elements" design
  handles a verse continuing across paragraph/line-break boundaries
  correctly, which react's `wrapVerseContent` fixtures alone didn't fully
  exercise.
- **Words-of-Christ stays theme-adaptive** (light `0xFFC02020`/dark
  `0xFFFF6B6B`, unchanged from when `ReaderColorScheme.wordsOfChrist` was
  first added) rather than copying Kotlin/React's single fixed red - both
  upstream SDKs actually ignore their own dark-mode contrast for this
  color (Kotlin's `ReaderColorScheme.wordsOfChristColor` field exists but
  is never read by the live reader screen, which hardcodes one red
  regardless of theme). Kept as a deliberate accessibility improvement
  over upstream, not "fixed" to match them.
- **`InlineSpan.recognizer` instead of Kotlin's character-offset hit
  testing**: Kotlin resolves a tap to a character index via
  `getOffsetForPosition`, then looks up which verse's reference annotation
  owns that index. Flutter's `TextSpan.recognizer` gives every verse's
  runs a shared tap target natively - a legitimate simplification enabled
  by the platform, not a corner cut; the end behavior (tap anywhere in a
  verse selects that whole verse) is identical.
- **Pre-existing dead-wiring bugs found and fixed while touching this
  code, not introduced by this change**: `ReaderFontSettings.darkMode` was
  persisted but never read by `BibleReader` (no `Theme` override existed
  at all before this change); `fontSize`/`lineHeight`/`fontFamily` were
  likewise never wired into `BibleTextTheme`; `VerseActionSheet`'s
  `onRemoveHighlight` was never connected to `deleteHighlight`; every
  highlight was created against the whole chapter id, not the tapped
  verse. All four fixed as part of the same `Theme`-override/verse-identity
  work since they touch the same code paths.

## USFM references, downloadable status, error codes (2026-08-24)

3 more cheap agents, this time checking against the official USFM reference
docs (`developers.youversion.com/usfm-reference`,
`github.com/youversion/usfm-references`) and error-codes docs
(`developers.youversion.com/error-codes`), plus Kotlin's
`BibleVersionDownloadStatus` enum the user found directly.

- **Real bug found and fixed, confirmed live**: `ChapterNavigation`
  (`packages/youversion_platform_reader/lib/src/navigation/chapter_navigation.dart`)
  and `ReferencesScreen`'s "Intro" chip both hardcoded a book's intro
  passage id as `'$bookId.intro'` (lowercase). Called the real API
  directly: `GET /v1/bibles/111/index` returns each book's intro as
  `{"id": "INTRO", "passage_id": "GEN.INTRO", ...}` (uppercase, no
  relation to the lowercased guess); `GET
  /v1/bibles/111/passages/GEN.intro` (our old hardcoded string) 404s,
  `GET .../passages/GEN.INTRO` (the real `passage_id`) returns 200. Fixed
  both call sites to read `BibleBookIntro.passageId` (already correctly
  parsed by the model - only the *callers* ignored it) instead of
  guessing. Also fixed a second bug this exposed: `ChapterNavigation.next`
  had no case for "currently on the intro, go to chapter 1" - only
  `previous` handled the intro as a boundary, `next` didn't have any way
  to detect "the current chapterId IS this book's intro" at all.
- **USFM ranges/multi-verse-selection/verse-part-suffixes**: confirmed
  present in the official spec (`MAT.1.1-MAT.1.5` ranges, `GEN.1.1+GEN.1.3`
  multi-select, `MAT.1.1a` part suffixes) but this package only ever
  passes USFM ids through as opaque strings - no parsing, validation, or
  normalization anywhere. Not fixed - this repo's `YouVersionHighlightsClient.deleteHighlight`
  doc comment already flags verse ranges as "don't have confirmed support"
  for one specific operation, and nothing in this package currently needs
  to parse a range/multi-select (content is always fetched and rendered
  per-chapter, not per-arbitrary-range). Logged in `BACKLOG.md` as a
  gap to watch, not implemented speculatively.
- **No canonical USFM book-code list/validator**: confirmed as a real gap
  (nothing validates `chapterId.split('.').first` against a known book-code
  set anywhere) but low-value to add pre-emptively - every book code this
  package ever sees comes from the API's own `getIndex` response, never
  user-typed input, so there's no real invalid-input scenario to guard
  against yet. Logged, not implemented.
- **`BibleVersionDownloadStatus` (Kotlin) confirmed NOT a gap**: it's
  purely local/client-side state for offline-caching UI (checks Kotlin's
  own on-device persistent cache, not any API field) - Kotlin's own
  `BiblesEndpoints.kt` has zero endpoints for it, and a `TODO` in
  `BibleVersionRepository.kt` shows even Kotlin's "is this bible allowed
  to be downloaded" check was never finished server-side. React has no
  equivalent at all. This repo's existing "storage-agnostic, no offline
  content cache" decision (see the "Design principle" section above)
  already correctly has nothing to model here.
- **Added `YouVersionErrorReason.rateLimited`** (`429`, confirmed
  documented at developers.youversion.com/error-codes with a `Retry-After`
  header). Applied universally in `YouVersionHttpClient._errorFor`,
  ahead of any per-client `reasonForStatus` - unlike `401`/`403` (which
  this package's own existing design deliberately maps differently per
  endpoint, see the `YouVersionErrorReason` doc comment), rate limiting is
  a protocol-level condition with the same meaning everywhere, so one
  universal check is correct rather than threading it through every
  client's own status-mapping function.
- **One error-codes finding rejected after verification**: an agent
  flagged Data Exchange's `401` → `notPermitted` mapping
  (`youversion_data_exchange_client.dart`) as a "mismap" that should be
  `missingAuthentication`. False positive - the `YouVersionErrorReason`
  enum's own doc comment already explains this exact case as intentional
  ("401 on Highlights is 'not authenticated'... on Data Exchange it's
  'token denied', permanent"). Not changed. A reminder that cheap-agent
  findings still need verification against the code's own stated intent
  before acting, not just against an external spec.
- **`406`/`400` on Content/Languages/Organizations left as the generic
  `cannotDownload` default**: flagged as a gap (these 3 clients pass no
  `reasonForStatus` at all, unlike Highlights/Data Exchange/Sign-In), but
  not fixed - inventing a specific per-status mapping without a confirmed
  real distinction (the way the `401` cases above were confirmed via
  Kotlin's own source) would be guessing, not verifying. Logged in
  `BACKLOG.md` for a future pass that actually confirms what each of
  these 3 modules' failure modes should map to.

## example/ apps, footnote UI, poetry lines, 401 mapping (2026-08-24, continuing the same session)

Closed 4 more items the user picked from `BACKLOG.md`:

- **`example/` apps**: `packages/youversion_platform_ui/example/` and
  `packages/youversion_platform_reader/example/`, standard pub.dev
  convention for a Flutter package (`example/pubspec.yaml` +
  `example/lib/main.dart`, no platform runner folders - those aren't
  needed for the pub.dev score, and are the separate still-open "smoke
  test on a real device" backlog item, not this one). `_ui`'s example
  needs no App Key (every widget takes hand-written sample data, per the
  package's own "never calls the network" design). `_reader`'s example
  can't avoid a real App Key - `BibleReader` needs real passage content -
  so it uses WEBUS (bible id `206`, public domain, no permissions
  required) and shows a friendly message (checking
  `YouVersionErrorReason.missingAuthentication`) instead of crashing when
  the placeholder key is left in place.
- **Footnote UI**: `BibleTextView` gained `onFootnoteTap`, with its own
  `TapGestureRecognizer` separate from the verse-selection one (tapping
  the `*` marker opens the footnote, it doesn't also select the verse).
  `BibleReader` wires it to a plain `showModalBottomSheet` with the note
  text - no new widget added to `_ui` for this, since `BibleCard`/
  `VerseOfTheDayCard` (the package's other `BibleTextView` consumers)
  don't need a footnote sheet, only the full reader does.
- **Poetry-line formatting**: `bible_text_node.dart`'s parser now
  recognizes `.q1`-`.q4`/`.qc`/`.qs` (USFM poetry-line classes) and emits
  a line-break run *after* each line's own content, not before - the
  line's own verse marker (if any) lives inside the `.q*` div itself, so
  the verse isn't known yet on entry; emitting the break on exit means it
  always lands under the correct verse regardless of whether that `.q*`
  div opened a new verse or continued the previous one (confirmed against
  the real Matthew 5:3 fixture, where `.q1` opens verse 3 and `.q2`
  continues it with no new `.yv-v` marker). Indentation itself is 2
  literal space characters per level, not a real hanging-indent paragraph
  style - same "not a general HTML engine" simplification already
  documented on this widget for other things.
- **401 on Content/Languages/Organizations**: mapped to
  `missingAuthentication`, confirmed live (empty/invalid App Key returns
  `401` with an Apigee gateway fault body, distinct from the app's own
  `{"message": ...}` `404` shape for a not-found resource). No `400`/`406`
  distinction added - none was reproduced against the real API despite
  deliberately probing for one (bad bible id, bad language id, bad
  organization id, malformed characters in a path segment - all landed on
  `404`, not `400`/`406`), so nothing was invented there.

## Real bugs found by actually running the reader example app (2026-08-24)

The user ran `youversion_platform_reader`'s example app for real (Linux
desktop, real App Key) for the first time - the first time any of this
session's work was exercised end-to-end instead of via `flutter test`
mocks. Found several real, previously-undetected bugs; all fixed and
covered by new tests:

- **`BibleChapter.id` is not a USFM reference - confirmed live, this broke
  chapter navigation entirely.** `GET /v1/bibles/{id}/index` returns each
  chapter as `{"id": "3", "passage_id": "JHN.3", ...}` - `id` is the bare
  local chapter number, `passage_id` is the real full reference. Every
  test fixture written earlier this session (including the ones that
  "confirmed" the intro-id fix) set `id` and `passage_id` to the *same*
  value, which accidentally matched the OLD, wrong code - masking this
  bug from every unit test written so far. `ChapterNavigation.previous`/
  `next` compared against `chapter.id`, so `chapterIndex` was always `-1`
  against real data - prev/next chapter buttons always disabled.
  `ReferencesScreen`'s chapter tap had the identical bug (passed
  `chapter.id` to `onChapterSelected`). `BibleReader._findPassageId`
  compared the same wrong field too, but its bug was masked by a fallback
  (`?? chapterId`) that happened to produce the right value for the
  *initial* chapter only (because the caller-supplied `initialChapterId`
  string is itself already a real passage id) - never for navigated-to
  chapters. Fixed all three call sites to use `chapter.passageId ??
  chapter.id`; `_findPassageId` became dead code once `chapterId` is
  guaranteed to already be a real passage id, so it was deleted rather
  than patched. Test fixtures updated to the real shape (bare `id`,
  distinct `passage_id`) so this class of bug can't hide again.
- **Reader theme (dark/light) conflicting with the host app's own ambient
  theme produced invisible text**: `ThemeData.copyWith(colorScheme: ...)`
  does **not** recompute an already-resolved `textTheme` - so overriding
  just `colorScheme.onSurface` left plain `Text` widgets (chapter id,
  etc.) colored for whatever brightness the *ambient* theme originally
  was, independent of the reader's own chosen theme. Confirmed by the
  user: system/ambient light + a dark reading theme (or the reverse)
  produced dark-on-dark or light-on-light text. Fixed with
  `ambientTheme.textTheme.apply(bodyColor: ..., displayColor: ...)`
  layered into the `Theme` override, plus `BibleTextTheme.fallback`
  gained an optional `color` parameter (previously always `null`,
  relying on ambient inheritance) so scripture text doesn't depend on
  that inheritance chain either.
- **`FontSettingsSheet`/`VerseActionSheet` selection state never visually
  updated on tap**: both were `StatelessWidget`s reading `settings`/
  `selectedColor` from the `showModalBottomSheet` `builder` closure,
  captured once. `showModalBottomSheet`'s `builder` isn't re-invoked just
  because the *caller's* state changes elsewhere - the sheet is a
  separate route. Tapping a chip/swatch called `onChanged`/
  `onColorSelected` correctly (the underlying setting/highlight did
  change), but the sheet's own UI kept showing the *old* selection until
  it was closed and reopened. Fixed by converting both to
  `StatefulWidget`s with a local copy of the value, updated synchronously
  on tap (still calling the same external callback for the real
  side-effect).
- **Applying/removing a highlight while signed out never marked the verse
  at all**: `_applyHighlight`/`_removeHighlight` only called
  `_controller.putVerseHighlight`/`removeVerseHighlight` in the
  signed-in branch - the signed-out branch queued the request
  (`PendingHighlightQueue`) but never touched local state, so picking a
  color while signed out looked like nothing happened. Fixed both to
  update local state optimistically first, regardless of sign-in state -
  the queued/deferred network call still happens the same as before, this
  only affects what's shown immediately. Removal has no offline queue at
  all (unlike creation) - a signed-out removal now only clears the local
  optimistic mark, which is honest (there was never anything sent to
  delete).
- **No way to switch Bible version from inside the reader at all** - user
  feedback ("não existe sistema de eleção de língua, versão"). Not a bug,
  a real missing extension point: `BibleReaderController.switchBible`
  existed, but nothing in `BibleReader`'s own UI ever called it, and there
  was no callback slot for a host app to hook in its own version-picker
  UI. Added `BibleReader.onVersionTap` (optional `VoidCallback`, same
  pattern as `onSignInRequested`) - shows a "change version" icon button
  in the app bar when set. Deliberately does *not* fetch/manage the list
  of available versions itself (which versions to offer is app policy,
  same reasoning `BibleVersionPicker`/`BibleLanguagePicker` already take a
  caller-supplied list rather than calling `listBibles`/`listLanguages`
  themselves) - the reader example now demonstrates wiring this to a real
  `BibleVersionPicker` + re-keying `BibleReader` on the selected version
  id, which forces a clean remount (`BibleReader` has no built-in
  reactive handling for its `bible`/`index` props changing post-`initState`).

## Full SDK demo app (2026-08-24, same session)

`youversion_platform_reader/example` grew from a single-screen anonymous
reader into the full demo app for the whole SDK - every
`youversion_platform_core` client, every sign-in/reading widget - per the
user's explicit request after the bug-fixing round above. Notable
decisions:

- **Real sign-in, "paste the callback URL" flow**: the App Key's only
  registered redirect URI (`https://api.symmetris.com.br/api/oauth/
  youversion/callback`) is another app's (Symmetris) production backend -
  unrelated to this SDK, and not something this example should ever
  actually call. Used that exact URI in `YouVersionSignIn(redirectUri:
  ...)` anyway (so `/auth/authorize` doesn't reject the request for an
  unregistered redirect), but the example never sends a request to it -
  after the browser redirects there, the user copies the URL straight out
  of the address bar (the `code`/`state` are plain, publicly-visible query
  params on that URL, readable whether or not the page itself loads) and
  pastes it into the app. Documented as a demo-only simplification in
  `sign_in_page.dart`'s doc comment - a real app registers its own deep
  link/App Link and skips this step. Same approach for the Data Exchange
  consent flow, whose callback is fixed/pre-registered rather than passed
  as a parameter at all.
- **`shared_preferences` added as a real dependency** of the example only
  (not the SDK packages themselves) - highlights/font settings/the sign-in
  session now survive a restart, matching what a real app would do.
  `SharedPreferencesReaderStorage` mirrors the exact implementation already
  given in `YouVersionReaderStorage`'s own doc comment.
- **`youversion_platform_ui`'s own example is unchanged** - stays a
  static, network-free widget gallery (no App Key needed). The full,
  real, end-to-end demo lives in `youversion_platform_reader`'s example
  instead, since that's the package that actually composes everything
  else - each README now points to the other as "see also".
- **App Key is not treated as a secret** - it's a public client identifier
  (same model as a Google Maps JS API key), confirmed by this package's
  own Sign-In design (`YouVersionSignIn`'s doc comment: "public client, no
  client_secret") - it appears in every request by design, across all 4
  official SDKs. What actually needs protecting is the user's OAuth
  access/refresh token, which is why the example persists *those* via
  `shared_preferences` and never hardcodes the App Key itself into a
  tracked file (`--dart-define=APP_KEY=...` at run time instead).

## Real OAuth sign-in tested live, 2 more real bugs found (2026-08-24, same session)

The user actually completed a real sign-in through the demo app's browser
flow for the first time - surfaced two more real, previously-unknown bugs:

- **`/auth/authorize` doesn't always redirect with `code` directly** -
  confirmed live (curled `https://api.youversion.com/auth/callback?state=...`
  with redirects disabled, got a `302` whose `Location` header finally
  carried `code`) and by tracing Kotlin's `UsersEndpoints.kt` all the way
  through (`getSignInResult` → `obtainLocation` → `obtainCode`) rather
  than just its public `exchangeCode`-equivalent signature. This package's
  own `YouVersionSignIn` doc comment previously *asserted* "the code
  arrives directly as a query param" as a stated assumption, not a
  verified fact - wrong for at least this App Key's configuration. Added
  `YouVersionSignIn.resolveCallback` (+ `YouVersionHttpClient.getRedirectLocation`,
  a redirects-disabled GET that returns the `Location` header) to perform
  the same hop Kotlin always does internally. **Not usable on Flutter
  Web** - browsers make a cross-origin manual-redirect fetch response
  opaque (no readable status/headers), a platform restriction, not
  something to route around.
  - Why this specific gap survived every earlier gap-sweep this session:
    every other sweep compared source code/behavior confirmable via
    `curl` + an App Key alone. This one only manifests with a *human*
    completing a real browser consent flow - no static read or automated
    agent sweep could have caught it. Worth remembering as a distinct
    category of gap from the others found today.
- **`YouVersionToken.fromJson` crashed on a real token response**:
  `expires_in` cast straight to `int`, but the server sends it as a
  string. Now accepts `int`/`String`/`num`.
- **A second instance of the "ambient theme vs. reader theme" color bug**,
  same session, different `ThemeData` slot: after fixing `textTheme` (see
  the earlier entry), the AppBar's auto-inserted back button (present
  whenever `BibleReader` is pushed onto a `Navigator`, as the demo app
  does) turned out invisible too - `IconThemeData`/`AppBarTheme.iconTheme`
  are separate from `textTheme` and need their own `.copyWith`/override.
  Looked exactly like "no way back to the menu" (a "gigantic bug" per the
  user's first read) but was actually just an unreadable icon the whole
  time - the pop still worked, tapping the invisible icon's hit area did
  navigate back. A reminder that this class of bug (ambient-vs-reader
  theme mismatch) likely has more instances across every `ThemeData` slot
  that resolves eagerly (`iconTheme`/`primaryIconTheme`/`appBarTheme`
  fixed now; re-check `chipTheme`/`dividerTheme`/etc. if a similarly
  "invisible" widget is ever reported again in the reader).

## 2026-08-24: more live-tested bugs, from the full demo app

- **`Highlight.id` crashed `Highlight.fromJson` when missing** - a real
  `createHighlight`/`listHighlights` response can omit `id` entirely
  (confirmed against Kotlin's own `Highlight.kt: id: String? = null`, and
  live). `Highlight.id` is now `String?`. This was the root cause of an
  "infinite loading" report: `BibleReader._loadChapter` had no error
  handling around the highlights fetch, so the uncaught type-cast
  exception left `isLoading` stuck `true` forever - looked like a hang,
  was actually a crash. Fixed both: `Highlight.id` nullable, and
  `_loadChapter` now wraps its body in try/catch/finally, surfacing a
  retry UI (`tryAgainButton`, new EN-only l10n key - no verified
  translation exists for it yet) instead of hanging or crashing silently.
- **"All buttons wrong color in dark theme" (not just the back button)**:
  the earlier fix (see prior entry, "second instance of ambient theme vs
  reader theme") patched `iconTheme`/`primaryIconTheme`/`appBarTheme`
  piecemeal on top of `ambientTheme.copyWith(colorScheme: ...)`, but more
  component themes than that resolve eagerly and don't get recomputed by
  `copyWith` (button themes among them). Whack-a-mole confirmed
  unsustainable. Fixed properly this time: construct a **fresh**
  `ThemeData(colorScheme: ..., extensions: [...])` instead of
  `.copyWith`-ing an inherited one - Material's own machinery then derives
  every component theme consistently from the `ColorScheme`, the same way
  a top-level `MaterialApp(theme:)` would.
- **Demo app: pagination gap in Bible Explorer/Languages** - both
  `listLanguages`/`listBibles` paginate (`next_page_token`), but the demo
  pages only ever requested the first page, which alphabetically is
  entries starting with "a". Not an SDK bug - `YouVersionCollection`
  already exposes `nextPageToken`/`hasNextPage` correctly - just the demo
  app not following it. Fixed by following every page before populating
  the language/version pickers and the Languages list.
- **Demo app: `NetworkImage("")` crash loop** - `YouVersionIdentity
  .profilePicture` can be `""` (empty string), not just absent/`null`,
  for a real signed-in user without a photo - confirmed live via the
  running app's logs (`EXCEPTION CAUGHT BY IMAGE RESOURCE SERVICE`,
  repeating every frame: `Invalid argument(s): No host specified in
  URI`). Not an SDK bug either (`YouVersionIdentity` decodes exactly what
  the server sends) - the demo's `CircleAvatar` now also checks
  `.isNotEmpty`, not just non-null.
- VOTD page's reported "badges form vertically, overflow the screen":
  re-inspected `votd_page.dart` - already a `SizedBox(height: 56)`
  wrapping a horizontal `ListView.builder`, which cannot overflow
  vertically. No reproduction, no code smell found. Likely reported
  against a build from before that layout existed; needs the user to
  re-confirm live against the current build before further chasing it.
- "Mixed Portuguese/English text" report: the SDK packages
  (`_ui`/`_reader`) correctly localize via `gen-l10n` - what's actually
  unlocalized is the demo app's own new pages (Bible Explorer, Languages,
  Organizations, VOTD, Data Exchange, Sign In), which are hardcoded
  English by design (it's a developer-facing reference app exercising
  every endpoint, not a polished end-user product). Not a bug; needs
  confirming with the user whether that's acceptable or the demo pages
  should also be localized.

## 2026-08-24 (cont.): 429 handling, end to end

Live retesting kept tripping `429 Too Many Requests` (confirmed:
`retry-after: 600` - a 10-minute lockout), largely self-inflicted by this
session's own testing (curl bursts + the demo's naive
follow-every-page-sequentially pagination loops added earlier today for
Bible Explorer/Languages, which fetched at the API's small default
`page_size` - dozens of rapid-fire requests instead of the 1-2 a large
explicit `page_size` needs). Real, fixable gaps found along the way:

- **`YouVersionException` had no way to know the real wait time.** Docs
  mention `Retry-After` but no client field exposed it. Added
  `YouVersionException.retryAfter` (`Duration?`), parsed from the header
  in `YouVersionHttpClient._errorFor` - confirmed live, sent as a plain
  integer-seconds string (`"600"`), not an HTTP-date.
- **Demo app: every list/detail page's `FutureBuilder` ignored
  `snapshot.hasError`** - any failure (429 included) left
  `CircularProgressIndicator` spinning forever, reading as "stuck loading"
  across Bible Explorer, Languages, Organizations, and VOTD simultaneously
  once the App Key got rate-limited (one 429 blocks every endpoint, not
  just the one that triggered it, for the full `retryAfter` window - so a
  single burst looks like the whole app broke). Added a shared
  `ErrorRetry` widget (`example/lib/error_retry.dart`) used everywhere: a
  human-readable message per `YouVersionErrorReason` (not the raw
  `YouVersionException(...).toString()`), and for `rateLimited`
  specifically a live countdown that disables the retry button until
  `retryAfter` elapses instead of inviting another guaranteed-to-fail tap.
- **`ErrorRetry` itself overflowed** (confirmed live, "RenderFlex
  overflowed by 100 pixels") when the caller's layout gave it a small
  fixed height (VOTD's day-strip `SizedBox(height: 56)`) - its
  icon+message+button column needs ~110px. Two-part fix: it now scrolls
  internally instead of overflowing regardless of the space it's given
  (`LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox`), and
  `votd_page.dart` no longer forces the error/loading states into that
  56px box to begin with - only the successful `ListView` state needs it.
- **`BibleReader` itself (the `_reader` package, not just the demo app)
  had the exact same two problems**: raw exception text in its own
  error-retry UI, and a `Center` with no scroll fallback for callers that
  embed it in a constrained area. Fixed the same way - friendly
  per-`YouVersionErrorReason` message, `retryAfter` countdown on the
  built-in retry button, `SingleChildScrollView` instead of bare `Center`.
  This one matters beyond the demo: any real app using `BibleReader`
  inherits this UI, not just this repo's example.
- **Demo app: unthrottled pagination loops were the actual trigger** for
  most of the 429s hit today. `listLanguages`/`listBibles` now pass an
  explicit `pageSize: 200` in the "load every page" loops
  (`languages_page.dart`, `bible_explorer_page.dart`), cutting a
  many-page burst down to 1-2 requests. Not a full fix for arbitrarily
  large result sets, but appropriate for this API's actual data volumes
  (see `docs/DECISIONS.md` pagination entry above) and enough to stop
  tripping the rate limiter in normal use.
- Also added `try`/`catch` around every remaining unguarded `await` in the
  demo pages (`sign_in_page.dart`'s callback exchange previously only
  caught `YouVersionException`, not e.g. a plain network error;
  `bible_explorer_page.dart`'s per-node fetch handlers had none at all) -
  each now surfaces a `SnackBar` instead of an uncaught exception.

## 2026-08-24 (cont. 2): the actual crash behind "Reader page crashes on 429"

What looked like the Reader itself crashing (full red error screen, no
AppBar/back button - matched Flutter's real crash overlay, not this
session's graceful error UIs) turned out to be a classic Dart gotcha in
the *demo app's* new retry buttons, not the SDK:

```dart
onRetry: () => setState(() => _future = _loadAll()),
```

`x = y` evaluates to `y`, so that arrow-body closure's return value is the
`Future` `_loadAll()` returns - and `setState()` asserts its callback must
be synchronous ("setState() callback argument returned a Future"),
throwing right there. This is thrown during a *gesture handler*, not
`build()`, so it bypasses `FutureBuilder`'s error handling entirely and
hits Flutter's top-level error overlay instead - explains the "no back
button, like a crash" symptom exactly (nothing built by this app's own
`Scaffold`/`AppBar` was even involved). Confirmed live via the exact
stack trace (`_LanguagesPageState.build.<anonymous
closure>.<anonymous closure>`).

Present in all 4 retry buttons added earlier today (`languages_page.dart`,
`organizations_page.dart`, `votd_page.dart`, `reader_page.dart`) - each
now uses a block-body closure (`setState(() { _future = ...; })`) instead,
which discards the assignment expression's value.

## 2026-08-24 (cont. 3): "load every page up front" was the wrong fix

The `pageSize: 200` bump (previous entry) itself turned out wrong too -
confirmed live, `page_size` is capped at 99 (`400: "page_size must be
between 1 and 99"`). Fixing the number wasn't the real fix, though:
`listLanguages`'s `total_size` is **8583** - even at the max page size
that's ~87 sequential requests, which either reads as infinite loading (no
error, just very slow) or trips the burst rate limiter again regardless of
page size. "Fetch every page before showing anything" is the wrong shape
for an endpoint this size, full stop.

Fixed properly: `LanguagesPage` now loads one page at a time with a "Load
more" button (real incremental pagination, what `next_page_token` is
actually for) instead of a blocking loop. `BibleExplorerPage`'s language
picker (`BibleLanguagePicker`, a `_ui` widget that takes a flat
pre-fetched list with no incremental-loading support of its own) only
offers the first page - a real app wanting the full list there would need
to extend the picker itself for incremental loading.

Checked whether the same "possibly long" problem applies to this app's
other list-then-await-everything spots - all confirmed small enough live
(`listBibles` per language: 20 for English; VOTD's `listAll`: fixed at
366 days, one request, not paginated at all; books/chapters/verses per
chapter: naturally bounded by real Bible structure) - so only
`listLanguages` needed this fix.

## 2026-08-24 (cont. 4): "Reader crashes" was really "no Scaffold yet"

One more round on the same symptom family ("no back button, like a
crash") - this time genuinely no exception anywhere (confirmed live: user
checked, no error in the log). `ReaderPage` is pushed directly via
`Navigator.push(MaterialPageRoute(builder: (_) => ReaderPage(...)))`, on
the documented assumption that "`BibleReader` supplies its own full
Scaffold/AppBar, so this page doesn't need one." True only *after* `_load`
(`getBible`+`getIndex`) succeeds at least once - before that,
`ReaderPage`'s `FutureBuilder` returns its loading spinner or `ErrorRetry`
completely bare, no `Scaffold` in sight anywhere in the tree yet. Explains
both complaints at once: no `AppBar` means no back button, and no
`Scaffold`/`Material` surface below the app-level one meant the text
looked unstyled floating on the page. Fixed by giving `ReaderPage` its own
`Scaffold(appBar: AppBar(title: Text('Reader')))` for exactly those two
pre-`BibleReader` states, leaving the success case (`BibleReader` itself)
untouched.

## 2026-08-24 (cont. 5): mixed-language sweep (3 light agents)

User-reported "app shows English and Portuguese mixed together." Ran 3
light `Explore` agents in parallel rather than guessing: (1) sweep the
demo app's own strings for accidental non-English text, (2) sweep
`_ui`/`_reader` widgets for strings bypassing their l10n accessors
(`youVersionUiStringsOf`/`youVersionReaderStringsOf`), (3) check the demo
app's `MaterialApp` locale configuration. Findings:

- Demo app's own strings: all genuinely English, nothing wrong there.
- **Two real SDK-level l10n bypasses, confirmed**:
  - `BibleReader._loadErrorMessage` (`bible_reader.dart`) built its 5
    error messages (rate-limited, sign-in-required, etc.) as hardcoded
    English literals, never routing through `youVersionReaderStringsOf`
    even though the rest of the widget does. Added `rateLimitedError`/
    `signInRequiredError`/`notPermittedError`/`invalidResponseError`/
    `loadFailedError` to both packages' full 14-locale `.arb` sets
    (English text for now for every locale except `pt`, which got a real
    hand-written translation - no verified upstream source exists for
    these since they're new to this SDK, same "don't fabricate" policy
    as the rest of this session's i18n work, `pt` is the exception
    because I write it directly, not machine-guessed).
  - `BibleVersionPicker`'s Bible-with-no-title fallback
    (`'Bible ${bible.id}'`) was hardcoded too. Added
    `bibleIdFallbackLabel` (same 14-locale treatment) to `_ui`.
- **Root cause of the actual "mixed" symptom**: the demo app's
  `MaterialApp` set no explicit `locale:`, so it followed the OS locale -
  meaning `_ui`/`_reader` widgets rendered in whatever the OS locale was
  (Portuguese here) right next to this app's own intentionally
  English-only page text (Bible Explorer, Languages, etc. - see the
  earlier "mixed Portuguese/English text" entry above, which correctly
  identified the *what* but not yet a fix). Pinned `locale: const
  Locale('en')` in the demo's `MaterialApp` so everything in this
  specific app matches. A real app localizing its own UI would instead
  let this follow the OS locale (or its own in-app language switcher).

## 2026-08-24 (cont. 6): localized the demo app's own text too

Follow-up to the settings-button work above: a locale picker that only
switched `_ui`/`_reader` widgets still left the demo app's own page text
(titles, buttons, messages) in English - the same "mixed languages" bug,
just narrower. User asked to handle it across the whole app.

Gave the example app its own `l10n.yaml`/`lib/l10n/example_{en,pt}.arb`/
`ExampleLocalizations` (same `flutter gen-l10n` setup as `_ui`/`_reader`,
added `flutter_localizations`+`intl` to its `pubspec.yaml`,
`generate: true`). Every real prose string across all ~10 page files now
routes through `ExampleLocalizations.of(context)` - API-method-name
subtitles (e.g. `"listBibles/getBible/getIndex/..."`) were deliberately
left as plain literals, they're code identifiers, not language.

**Only `en`/`pt`, not the SDK's 14** - `_supportedLocales` in `main.dart`
is `[Locale('en'), Locale('pt')]`, and the language-picker dialog was
narrowed to match. Offering the other 12 SDK-only locales here would
recreate the exact bug being fixed: this app's own text has no
translation for them, so picking e.g. `fr` would show `_ui`/`_reader`
widgets in French next to English demo text again - worse, it also risks
a hard crash, since `nullable-getter: false` means `ExampleLocalizations`
requires every configured `supportedLocale` to actually have a
translation; picking an unsupported one throws at the `Localizations`
resolution layer, not gracefully falls back. A real app should only ever
list the locales it has actually localized *itself* into, not just
whatever the SDK happens to support - same reasoning here.

## 2026-08-24 (cont. 7): Bible Explorer gets Reader-parity features, inline

User wanted Bible Explorer to have the same interactions as `BibleReader`
(colored/highlighted text, verse tap, copy/share) - explicitly *without*
navigating to a new screen (ruled out earlier in this session: pushing a
real `BibleReader` route was the obvious low-effort path, rejected in
favor of staying inline and "making widgets reusable" instead).

Two real, reusable pieces were extracted out of `BibleReader` for this
(both now public from `_reader`'s barrel):

- **`ReadingThemeScope`** (`lib/src/theme/reading_theme_scope.dart`) - the
  fresh-`ThemeData`-from-`ReaderFontSettings` construction that took
  several live-bugfix rounds to get right (see the "second instance of
  ambient theme vs reader theme" and "all buttons wrong in dark theme"
  entries above) was duplicated logic waiting to happen the moment a
  second reading surface needed it. Extracted verbatim, `BibleReader`
  itself now just wraps `_buildScaffold` in it.
- **`extractVersePlainText`** (`_ui`, `rendering/bible_text_node.dart`) -
  parses `BiblePassage.content` (already needed for display via
  `parseBibleHtml`) and returns one verse's plain text by local number.
  Needed for copy/share, which want plain text, not YVDOM HTML.

Also fixed a real, pre-existing gap while wiring this: `BibleReader`
itself never actually wired `VerseActionSheet`'s `onCopy`/`onShare`
callbacks (the widget always supported them, `bible_reader.dart` just
never passed anything) - copy/share never worked in the Reader either,
this whole feature request surfaced it. Added `BibleReader.onCopyVerse`/
`onShareVerse` (`null` hides the button, same pattern as `onVersionTap`;
this package stays free of a clipboard/share dependency of its own, the
host app's callback owns the platform action). Also relaxed
`_openVerseActions`'s early-return: it used to skip the whole sheet
(including copy/share) whenever no `highlightsClient` was configured -
now only skips when neither highlighting nor copy/share would show
anything.

`BibleExplorerPage` (the demo app) now reuses `BibleReaderController`\*/
`PendingHighlightQueue`/`ReaderSettingsStorage`/`ReadingThemeScope`/
`FontSettingsSheet` directly - real persisted highlight colors (same
offline-queue-when-signed-out behavior as the Reader), copy/share, and a
reading theme/font shared with the Reader (same default storage key, so
a theme picked in one shows in the other). Also persists the last
language/book/chapter/verse position locally (`YouVersionReaderStorage`),
restoring it on next open instead of always starting from the country/
language picker - falls back to that picker if the saved position is
stale (a deleted bible/book/chapter server-side) rather than getting
stuck.

\* Explorer ended up managing its own small parallel state (`_bible`/
`_book`/`_chapter`/`_selectedVerseId`/`_verseHighlights`) rather than a
`BibleReaderController` instance directly - the controller's shape (single
`chapterId`, `ChapterNavigation`-based prev/next) doesn't fit Explorer's
book/chapter/verse *drill-down* navigation model. Only the pieces that
generalize (queue, settings storage, theme scope) were reused as-is.

## 2026-08-24 (cont. 8): tap-to-select / long-press-to-act, multi-select

User wanted the official YouVersion app's verse-selection model in Bible
Explorer: tap selects/deselects a verse (dashed underline only, no sheet),
tap several to multi-select, long-press one to act on everything selected
(copy/share/highlight all at once) - explicitly flagged as "the official
app's feature, not the SDK's own opinion."

`BibleTextView.selectedVerseId` (`String?`) became `selectedVerseIds`
(`Set<String>`) - a breaking but pre-1.0 change, `BibleReader` updated to
pass a single-element set (its own tap-opens-sheet-immediately behavior is
unchanged, it just doesn't use multi-select or the new long-press
callback). Added `onVerseLongPress`, separate from `onVerseTap`.

**Real Flutter constraint found getting long-press working on inline
text**: `TextSpan.recognizer` accepts any `GestureRecognizer`, but
`RenderParagraph.assembleSemanticsNode` only supports Flutter's own
recognizer types when building the semantics tree - a custom
`GestureRecognizer` subclass throws `"X is not supported"` there (crashed
building the very first frame in a widget test). Not fixable by
subclassing more carefully - it's a hardcoded type check, not a
capability gap. Worked around it by not subclassing at all: a real
`TapGestureRecognizer`'s `onTapDown`/`onTapUp`/`onTapCancel` are enough to
hand-roll tap-vs-long-press timing (`kLongPressTimeout`) while staying a
type `RenderParagraph` actually recognizes (`rendering/
verse_gesture_recognizer.dart`, `_ui`).

Bible Explorer's own selection/action-sheet logic was rewritten around
the new `Set<String>` model: tap toggles a verse in/out of
`_selectedVerseIds`; long-press starts a one-verse selection if nothing
was selected yet, then opens `VerseActionSheet` for the *whole* set -
combined plain text for copy/share (each verse's text via
`extractVersePlainText`, joined with a blank line), a shared highlight
color only if every selected verse already has the same one, and
apply/remove-highlight loop over every selected id.

Two more real bugs found and fixed while wiring this - both about
"resume where you left off" not actually working:

- `_savePosition` persisted `_selectedVerseId` (only ever set by tapping
  *inside* the rendered passage) but the far more common path - picking a
  verse from the verse-chip list - only ever set the separate
  `_flashVerseId`, so the saved position silently dropped the verse most
  users would have actually picked. Now saves whichever is non-empty.
- `_restorePosition` only called `_openChapterPassage` `if (verseId !=
  null)` - a saved position with a chapter open but no specific verse
  picked yet never loaded the chapter's passage content at all on restore
  (looked like "the rest doesn't load" - the chip lists would show, the
  actual scripture text never would). `_openChapterPassage(null)` is a
  perfectly normal call (`_openChapter` already makes it) - just needed
  to stop gating it.

## 2026-08-24 (cont. 9): collapsible Book | Chapter | Verse picker

UX request: Bible Explorer's book/chapter/verse chip lists used to all
stack vertically at once (pick a book, its chapter list appears below,
pick a chapter, its verse list appears below that too) - user wanted a
segmented "Book | Chapter | Verse" header instead, where tapping a
segment expands just that section's chip list (collapsing the others),
and picking an item auto-advances to the next segment, ending fully
collapsed once a verse is picked - "melhor para UX" than always showing
every level stacked.

Implemented as a single `_ExplorerSection? _expandedSection` (`book`/
`chapter`/`verse`/`null` = all collapsed) driving one `if/else if/else
if` instead of the previous 3 independent `if (_book != null) [...]`
blocks - only one `FutureBuilder`+`Wrap` is ever in the tree at a time.
`_openBook`/`_openChapter`/`_openVerse` each advance it
(`book`→`chapter`→`chapter`→`verse`→`verse`→`null`); restoring a saved
position starts fully collapsed (everything already picked, no reason to
show a picker); picking a new bible version resets to `book`.

## 2026-08-24 (cont. 10): real copy/share text format, not just verse text

Copy/share was sending just the raw joined verse text. Researched what
the official SDKs actually do before inventing a format:

- **Share text** (curly-quoted text + blank line + reference + version) -
  confirmed against `platform-sdk-react`'s `buildVerseShareText`/
  `buildVerseReference` (`packages/ui/src/lib/verse-share.ts`, citing
  ADR-006/YPE-642). Verse numbers collapse to ranges within a contiguous
  run (`"1-3"`) and comma-separate between runs (`"1,3"`); texts join with
  a space within a run, `" ... "` between runs. Confirmed live against
  their test fixtures, e.g. `Proverbs 19:1,3 NIV`.
- **Deeplink URL** - confirmed against `platform-sdk-kotlin`'s
  `BibleVersion.shareUrl` (`bibles/models/BibleVersion.kt`):
  `bible.com/bible/{versionId}/{BOOK}.{chapter}.{verseRange}.
  {abbreviation}`, falling back to the numeric bible id when there's no
  abbreviation. Confirmed against its own test fixtures (`1SA.3.10.NIV`,
  `1SA.3.10-15.NIV`).
- **Combining quote+reference with a URL** has no confirmed precedent in
  either reference SDK - neither concatenates a URL into share text
  themselves. This demo's own layout choice (quote, blank line,
  reference, URL), not a ported format - flagged as such in
  `_buildShareText`'s doc comment so it's not mistaken for a verified
  upstream contract like the two pieces above.
- **No full copyright line**, dropped after asked "is all this copyright
  necessary?" - confirmed live it's a multi-line legal paragraph (NIV:
  168 chars, NASB: 210+), not a short credit, and neither reference SDK's
  share format includes one - the version abbreviation already in the
  reference line is the attribution.

## 2026-08-24 (cont. 11): desktop loopback sign-in (RFC 8252)

User wanted the paste-the-callback-URL desktop sign-in flow replaced with
a real automatic one, same idea Symmetris' own Flutter desktop app uses:
open the system browser for login, catch the redirect on a temporary
local HTTP server instead of a custom-scheme deep link (which the OS
never registers for a desktop build the way it does on Android/iOS).

Added `OAuthLoopbackServer` to `_core` (`sign_in/oauth_loopback_server.dart`)
- plain `dart:io` `HttpServer.bind(InternetAddress.loopbackIPv4, port)`,
  no new dependency (not even `shelf`). `start()`/`waitForCallback()`/
  `dispose()`, closes itself after exactly one request or a timeout.

**Real cross-platform-compile risk caught before it shipped**: exporting
this from the package's top-level barrel unconditionally would have broken
*any* Flutter Web build of *any* app depending on this package, even one
that never touches sign-in at all - `dart:io` doesn't compile for web,
full stop, and Dart resolves `export`s at compile time regardless of
whether the symbol is ever used. Fixed with a conditional export
(`export 'oauth_loopback_server_stub.dart' if (dart.library.io)
'oauth_loopback_server.dart'`) - a stub with the identical public API
(`start()` just throws `UnsupportedError`) stands in on web. Same
reasoning applied to the demo app's own platform check: used
`defaultTargetPlatform`/`kIsWeb` (`package:flutter/foundation.dart`)
instead of `Platform.isLinux` etc., since the example app also has a
`web/` target and a bare `dart:io` import in `sign_in_page.dart` would
have broken *that* build the same way.

**Fixed port, not OS-assigned** (`port: 0`) - RFC 8252 §7.3 says the
*port* specifically shouldn't need pre-registration for a loopback
redirect_uri, but whether YouVersion's `/auth/authorize` actually
implements that leniency or does an exact string match including the
port was not confirmed ahead of time, so a fixed port works under either
behavior. `8952` was picked and registered.

**This App Key only supports one registered `redirect_uri`, not several**
- confirmed live: the original plan here was a *second* redirect_uri
  registered alongside the existing Symmetris one (paste-flow keeps
  working regardless of whether loopback registration was done), each
  flow using its own `YouVersionSignIn` instance. Pointing
  `/auth/authorize` at the unregistered loopback URI while Symmetris was
  still the registered one didn't error - it silently landed back on
  Symmetris instead (matches `/auth/authorize`'s own behavior seen
  earlier for `resolveCallback`: it tends to fail soft, not loud). Fixed
  by simply replacing the single registered `redirect_uri` with the
  loopback one - `SignInPage` now uses `widget.signIn` (one instance) for
  both flows, deriving `OAuthLoopbackServer`'s `port`/`path` by parsing
  `widget.signIn.redirectUri` rather than a separate constant, so
  there's exactly one source of truth for what's actually registered.
  The desktop auto-sign-in button only shows when that `redirectUri` is
  actually a loopback address (`_isLoopbackUri`), guarding against
  `OAuthLoopbackServer` trying to bind an unrelated port (e.g. `443`) if
  it's ever changed back to something else.

**A second, more interesting bug** surfaced once the redirect_uri was
right: the browser genuinely landed on `http://127.0.0.1:8952/callback`
with the real `state`/`granted_permissions`, but the local server "didn't
respond." Symmetris' own `OAuthLoopbackServer` (which this was modeled
on, confirmed working in their production app) uses the exact same
`server.first` pattern - grab whichever request arrives first, answer it,
close. The difference: Symmetris' loopback redirect always comes from
*their own backend*, which only ever issues one clean request here.
Here, the redirect comes from a real third-party login/consent page
(login.youversion.com) - if its page issues anything else to this origin
first (a favicon request, a CORS preflight), `server.first` answered
*that* instead and closed the server before the real navigation request
ever arrived - "the port already stopped responding" is exactly what a
closed listening socket looks like from the browser's side. Fixed by
looping instead of taking the first event: only a request matching the
expected `path` resolves/closes the server, everything else gets a `404`
and the server stays open. Added a regression test
(`oauth_loopback_server_test.dart`) simulating exactly this - a stray
`/favicon.ico` request before the real `/callback` one - to lock it in.

## 2026-08-24 (cont. 12): VOTD picker - chips, then Wrap, then a date picker

VOTD's day-strip went through 3 iterations before landing right:

1. Horizontal-scrolling `ListView` of 366 `ChoiceChip`s - confirmed live,
   scrolling that many chips sideways past the edge of the screen (no
   visible affordance that there's more) read as "passing the width of
   the screen".
2. Switched to `Wrap` (matches Bible Explorer's book/chapter/verse chips
   - wraps to multiple rows instead of scrolling one long row). Fixed the
   width complaint, but 366 chips wrapped into rows just took over the
   whole screen instead - a real "too many items" problem, not a layout
   bug.
3. Replaced the chip list entirely with a date picker -
   `YouVersionVotdClient.getDay` addresses a day by ordinal (1-366,
   day-of-year), but nobody actually thinks in day-of-year; a calendar
   date, converted to day-of-year locally
   (`date.difference(DateTime(date.year)).inDays + 1`), is both the more
   recognizable UI for "verse of the day" and never renders more than one
   control. `listAll` (previously called just to build the chip list) is
   no longer used by this page at all - `getDay` alone is enough.
   Tried `CupertinoDatePicker` (a scrolling wheel, in a bottom sheet)
   over `showDatePicker`'s calendar grid - works on every platform (not
   gated by OS), user preferred it initially.
4. **Mobile only**, in the end - confirmed live on Linux desktop, the
   wheel picker (`ListWheelScrollView` under the hood) has two real
   Flutter-level papercuts with a physical mouse: each wheel notch jumps
   several items (a mouse's scroll delta per notch is much larger than
   what the widget expects, and it isn't scaled down), and click-and-drag
   doesn't scroll it at all (Flutter's default `ScrollBehavior` only
   enables drag-to-scroll for touch/stylus pointers, not mouse). Neither
   is specific to this app or fixable without patching Flutter's own
   scroll behavior/physics - `isDesktopPlatform` (`_isDesktop`, extracted
   here from `sign_in_page.dart` into a shared `platform_check.dart`
   since two files needed it) now picks `showDatePicker`'s calendar grid
   on desktop (plain taps/clicks, no wheel/drag needed) and keeps the
   Cupertino wheel for mobile, where touch-scrolling one works fine.

Not confirmed whether `getDay` resolves across a year boundary (e.g. day
366 of a leap year vs. day 1 of the next) - both pickers' `minimumDate`/
`maximumDate`/`firstDate`/`lastDate` are clamped to the currently-selected
year rather than assuming either way.

## 2026-08-24 (cont. 13): right-click as an alternative to long-press

`verseTapLongPressRecognizer` (`_ui`, `rendering/verse_gesture_recognizer.dart`)
already hand-rolls tap-vs-long-press timing on top of a real
`TapGestureRecognizer` (custom `GestureRecognizer` subclasses crash
`RenderParagraph`'s semantics-tree assembly - see cont. 9/earlier).
Requested: besides press-and-hold, let a mouse right-click also open the
verse context menu - a purely desktop-native gesture, no touch/mobile
equivalent expected.

`TapGestureRecognizer` already supports the secondary mouse button
natively via `onSecondaryTapUp`/`onSecondaryTapDown`/`onSecondaryTapCancel`
on the *same* recognizer instance already wired for primary-button
tap/long-press - no second recognizer needed. Wired
`recognizer.onSecondaryTapUp = (_) => onLongPress?.call()`: right-click
fires the exact same callback long-press does, immediately (no timer),
since it's meant as an alternative trigger for the identical action, not
a separate new one.

## 2026-08-24 (cont. 14): Bible Explorer header - pinned, version name as its own "change" button

Two related UX requests on the Bible Explorer page:

1. The Version / Book / Chapter / Verse header row should stay visible
   while scrolling the passage text below, not scroll away with it (it
   used to live inside the same `ListView` as the passage).
2. Remove the separate "Trocar idioma/versão" button - the version name
   text itself (where it already shows the current Bible's title) becomes
   the tappable control that opens the language/version picker.

Fixed by splitting `build()`'s single scrolling `ListView` into a
`Column`: a non-scrolling `Padding` at the top holding the version
row + the Book|Chapter|Verse segmented picker (and its expanded chip
list, when a section is open) - always on screen regardless of how far
the passage text below is scrolled - and an `Expanded(child: ListView(...))`
below it holding only the chapter passage (`BibleTextView`) and its
error/loading states. The version `Text` became a left-aligned
`TextButton` wrapping `_pickLanguage`; the old `TextButton(child:
Text(strings.changeButton))` was removed, and `changeButton` dropped from both `ExampleLocalizations` ARB
locales (`example_en.arb`/`example_pt.arb` - this app's own strings are
en/pt-only, see earlier decision) since nothing references it anymore;
`flutter gen-l10n` regenerated the `.dart` delegates from the edited ARBs
rather than hand-editing the generated files.

## 2026-08-24 (cont. 15): previous/next chapter buttons around the passage

Bible Explorer already caches nothing about the book's chapter order -
the chapter chip list fetched `listChapters` fresh every time that
section expanded. Requested: a "previous chapter" button above the
passage and a "next chapter" one below it.

Fetched `listChapters` once per book instead, in `_openBook`/
`_restorePosition` (stored in new `_chapters` state), reused by both the
chapter chip `Wrap` (no more redundant `FutureBuilder` fetch) and a new
`_chapterAtOffset(delta)` lookup (index of `_chapter` in `_chapters`,
±1, bounds-checked). `_ChapterNavButton` renders nothing
(`SizedBox.shrink`) at either end of the book - no wraparound into an
adjacent book, out of scope here - otherwise a full-width
`OutlinedButton.icon` that calls the existing `_openChapter`. New ARB
keys `previousChapterButton`/`nextChapterButton` (en/pt only, same as
the rest of `ExampleLocalizations`).

## 2026-08-24 (cont. 16): reader footer wired to the wrong field - `info` vs `copyright`

Reported: no copyright/credit text ever shows below the last verse in
either the Reader or Bible Explorer, despite `BibleTextView.footer`
already being wired (`bible_reader.dart:419`, `bible_explorer_page.dart`
footer:) and `BibleTextView` already rendering it when non-empty
(`bible_text_view.dart:203-206`, `caption` style, 11pt - small but
present by design, matching the Kotlin SDK's own type scale).

Root-caused live: curled `GET /v1/bibles/{id}` (`X-YVP-App-Key`,
`api.youversion.com`) for 3 real bibles (206/WEBUS, 1/KJV, 111/NIV).
`info` (mapped to `Bible.readerFooter`, the field the footer was wired
to) is `null` for **all three** - never populated in practice, not just
for these particular ones. `copyright` (already a separate parsed field,
`Bible.copyright`, but never fed into `BibleTextView.footer` anywhere)
*is* populated when there's real legal text to show - NIV's full
"Copyright © 1973, 1978, 1984, 2011 by Biblica, Inc.®..." credit came
back verbatim; WEBUS/KJV correctly return `null` there too (genuinely
public domain, nothing to credit).

Fixed both call sites to `bible.copyright ?? bible.readerFooter` - prefer
the field that's actually populated, keep `readerFooter` as a fallback in
case some other bible ever populates only that one instead (never
observed, but the field exists in the API contract, so not assuming it
never will). Not a change to the earlier cont. 10 decision (no full
copyright line in *share text*) - that was specifically about not
bloating a copy/share payload with a paragraph of legal boilerplate; this
is the reading screen's own persistent credit line, shown once, exactly
where real Bible apps put it.

## 2026-08-24 (cont. 17): prev/next chapter buttons land at the end/top, not wherever the scroll happened to be

The prev/next chapter buttons added in cont. 15 called `_openChapter`
directly - the passage's own `ListView` kept whatever scroll offset it
was already at, so "next chapter" could land mid-scroll into the new
chapter instead of at its top, and "previous" likewise. Requested:
"next" should land at the top of the new chapter, "previous" at its end.

Added a `ScrollController` (`_passageScrollController`) to the passage
`ListView` and two thin wrappers, `_goToNextChapter`/
`_goToPreviousChapter`, that `await _openChapter` then
`jumpTo(0)`/`jumpTo(maxScrollExtent)` inside a post-frame callback - not
immediately after the `await`, since `_openChapterPassage`'s `setState`
only *schedules* the rebuild; jumping before that frame's layout runs
would read the *old* chapter's `maxScrollExtent`. `addPostFrameCallback`
guarantees the new chapter's `BibleTextView` has already been laid out.

## 2026-08-25: in-flight request dedup + in-memory cache (`_core`)

The user pointed at platform-sdk-kotlin's `bibles/domain/BibleVersionRepository.kt`
directly (a `Map<Int, Deferred<BibleVersion>>` guarded by a `Mutex`,
plus `bibles/domain/BibleChapterRepository.kt`/`BibleIntroRepository.kt`
doing the identical thing for chapter/intro fetches): two concurrent
calls for the same bible/chapter/passage fire only one real HTTP
request, the second caller awaits the first's in-flight result instead
of duplicating it. `YouVersionContentClient`/`YouVersionLanguagesClient`
had nothing equivalent - confirmed live via 2 parallel `Explore` agents
(one mapping every method's cache-candidacy, one sweeping the other
reference SDKs for related gaps) that every call, even an identical
concurrent one, fired its own request.

**Not the same thing as the already-declined "HTTP caching layer" /
"no offline content cache" item** (`BACKLOG.md`, `docs/DECISIONS.md`'s
"storage-agnostic" principle near the `BibleVersionDownloadStatus` note)
- that decision is specifically about Kotlin's *persistent*, on-device
cache tiers (`persistentCache`/`temporaryCache`, survives app restart,
this package's stance is that's the host app's job). This is a
different, narrower thing: a plain in-memory `Map`, scoped to one client
instance, cleared on `close()`, never touching disk. Doesn't reopen the
prior decision.

Implementation: a generic `_dedupedCached<T>(key, fetch)` helper on both
clients (`Map<String, Object?> _cache` + `Map<String, Future<Object?>>
_inFlight`) - checks the cache, then the in-flight map, else calls
`fetch()` and stores the `Future` in `_inFlight` *before* the first
`await` inside it runs. No `Mutex`/lock dependency needed for this,
unlike Kotlin: Dart's event loop is single-threaded, so storing the
`Future` synchronously in the map is enough to make a second synchronous
call see it already there - there's no window for two `Future`s to be
created for the same key. A failed fetch is never cached (only removed
from `_inFlight`, via `whenComplete`), so a retry after an error fires a
real request again.

Scope, per the user's explicit ask (not just single-object methods):
`getBible`/`getIndex`/`getPassage`/`getBook`/`getChapter`/`getVerse` (all
keyed by their id/USFM parameters - Bible content is immutable per id in
practice) and also `listBibles`/`listBooks`/`listChapters`/`listVerses`
(keyed by their full parameter tuple, including `pageToken` where
relevant, so different pages/filters get their own cache entry, never a
false collision) on `YouVersionContentClient`; `getLanguage`/
`listLanguages` (keyed including the `country` filter) on
`YouVersionLanguagesClient`. `getPassage` alone covers book-intro content
too (fetched via `passageId`, no separate intro method exists in this
port unlike Kotlin's dedicated `BibleIntroRepository`), so no extra
wiring was needed for that case.

**Other, larger gaps found during the sweep, logged to `BACKLOG.md`
(local, gitignored) rather than implemented here**:
- Kotlin's `highlights/domain/BibleHighlightsRepository.kt` +
  `BibleHighlightCache.kt` (~1200 lines) - a full offline-first sync
  engine for highlights (optimistic writes, an operation queue with
  exponential backoff, 403-reconciliation, per-chapter load dedup,
  queue invalidation on account switch). `YouVersionHighlightsClient`
  here is a thin stateless CRUD wrapper by comparison - a real, much
  bigger gap, tracked separately, not attempted as part of this change.
- React's `Users.ts` `inFlightCodeExchanges`/`inFlightRefresh` (dedup for
  concurrent OAuth code-exchange/token-refresh calls, preventing a
  single-use code/refresh-token from being spent twice) - only
  corroborated by React, not Kotlin; lower priority since this SDK
  doesn't yet do proactive expiry-driven auto-refresh for anything to
  race on. Logged as an open item.
- Kotlin's `YouVersionApi.hasValidToken()` (proactive expiry check +
  auto-refresh) - folded into the already-declined "Token storage/
  persistence" item's rationale rather than a new entry; it fundamentally
  needs persisted expiry state this package leaves to the host app.

## 2026-08-25 (cont. 2): `YouVersionHighlightsSyncEngine` - offline-first highlights sync

Follow-up to the dedup gap-sweep above. `YouVersionHighlightsClient` was
a thin stateless CRUD wrapper - no cache, no retry, no coordination.
Kotlin's `highlights/domain/BibleHighlightsRepository.kt` +
`BibleHighlightCache.kt` (~1200 lines combined) implement a real
offline-first sync engine: optimistic local writes, a retry queue with
exponential backoff, account-wide `403` handling that doesn't wedge the
queue, per-chapter load throttling/dedup, and session-scoped
invalidation. Investigated via 2 parallel `Explore` agents (one mapping
the current Dart state, one reading Kotlin's implementation in full)
before designing anything - full mechanics (backoff formula, generation
guard, 403 handling, chapter throttle) confirmed against real Kotlin
source, not summarized from memory.

**Key finding that shaped the design**: Kotlin's `queuedOperations`
(`MutableStateFlow<List<PendingHighlightOperation>>`) is *also* purely
in-memory - explicitly documented in Kotlin's own comments as lost on
process death. This isn't a gap relative to this repo's "storage-
agnostic, no offline content cache" principle (see the cont. 1 entry
above and the earlier `BibleVersionDownloadStatus` note) - it's the same
principle, already satisfied. So `YouVersionHighlightsSyncEngine`
(`packages/youversion_platform_core/lib/src/highlights/domain/
youversion_highlights_sync_engine.dart`) is memory-only too, cleared on
`close()`.

**Resulting split, not a replacement**: `youversion_platform_reader`'s
`PendingHighlightQueue` (persisted via `YouVersionReaderStorage`)
already covers "app closed while signed out, resume later" - something
Kotlin doesn't even attempt (no persisted state at all). The new engine
covers a different concern: robustness *during* a running session -
retry with backoff, not spamming `listHighlights` for the same chapter,
not wedging the queue on a permission refusal, dropping zombie retries
after a sign-out. Both stay, each doing the part the other doesn't.

Adaptations from Kotlin to idiomatic Dart (documented in the class's own
doc comment, not just here):
- **No `Mutex`**: same reasoning as the content-client dedup work - the
  event loop is single-threaded, and this engine's queue/cache mutations
  are synchronous chunks between `await` points, so nothing needs a lock.
- **No `StateFlow` per query**: Kotlin exposes `highlights`/
  `pendingOperationCount`/`failedOperationCount` as separate reactive
  streams. Dart uses one broadcast `Stream<void> changes` that fires on
  any observable mutation; callers re-read synchronous getters
  afterward. Simpler than building a mini-reactive-stream system, still
  enough to drive a `setState`. A deliberate simplification, not a
  missed port.
- **No structured `BibleReference`**: this repo already decided not to
  build USFM range parsing (`BACKLOG.md`). Operations key directly on
  `bibleId`/`passageId` (verse-level USFM, e.g. `JHN.3.16` - the
  vocabulary `YouVersionHighlightsClient` already uses) plus an explicit
  `chapterId` parameter for the load-throttle key, passed by the caller
  rather than parsed out of `passageId`.
- **`Timer`/`Future` loop, not a coroutine `Job`**: `while(true)` +
  `delay()` became a recursive `_processQueue` that `await`s
  `Future.delayed(backoff)` between batches - same effect, no
  `dart:isolate`/external package dependency.

**One faithfully-preserved surprise**: `pendingOperationCount` reads `0`
while a batch is claimed and in-flight, exactly like Kotlin's
`queuedOperations.map { it.size }` - the processor empties the queue
list the moment it claims a batch, before any `await` suspends. Confirmed
live in this port's own tests (`hasPendingOperations`, not
`pendingOperationCount`, is the one that stays `true` for the whole
in-flight window - matches Kotlin's own `hasPendingOperations()` doc
comment, which explicitly calls out the same gap for the same reason).

**Simplification in the 403 handling**: Kotlin tracks a per-batch
`rejectedReferences` list plus a separate `abandonRefusedWrites` pass
with fine per-reference bookkeeping. This port collapses that to: on the
first `notPermitted` in a batch, mark every remaining operation in that
batch *and* anything left in the live queue as rejected (same end
result - permission refusal is account-wide, not per-operation, so
nothing partial should survive it), then trigger a `forceReload` on each
distinct affected chapter. Functionally equivalent, less bookkeeping
machinery.

Not ported (deliberately out of scope, see `BACKLOG.md`): Kotlin's
read-path `403` behavior of wiping the *entire* cache
(`cache.clear()` on a chapter-load 403, not just a write 403) - not
carried over here; a load 403 in this port just leaves that chapter's
data as-is (stale-but-present) rather than nuking every other chapter's
cache too. Revisit if this ever causes a real observed issue.

**Wired into `BibleReader`** (`youversion_platform_reader`, same day):
`_applyHighlight`/`_removeHighlight` previously called
`YouVersionHighlightsClient` directly when signed in (no retry on
failure - an exception there wasn't even caught) and only used
`PendingHighlightQueue` when signed out. Both now route their signed-in
write through the new engine's `setHighlight`/`removeHighlight` instead
- fire-and-forget, matching the engine's own API (the optimistic
`_controller.putVerseHighlight`/`removeVerseHighlight` call already
present stays the UI's source of truth; the engine's own cache isn't
consulted for rendering, only used for its sync bookkeeping). Also calls
`reset()` on the sign-in→signed-out transition in `didUpdateWidget`
(mirroring the existing sign-out→sign-in transition that already
triggers `PendingHighlightQueue.replay`), so a retry still backing off
from the old session is dropped instead of resent under a new session.

**Not done, left for a follow-up** (`BACKLOG.md`):
`PendingHighlightQueue.replay` still calls
`YouVersionHighlightsClient.createHighlight` directly rather than
pushing into the engine - a replayed request on sign-in still doesn't
get retry/backoff if it fails (same behavior as before this change,
just not improved yet). `bible_explorer_page.dart` (this repo's example
app, and the sibling `bible_with_me` app) also has its own
near-duplicate apply/remove logic, untouched.

## Where to log future changes

- **`packages/youversion_platform_core/CHANGELOG.md`**: what changed, per
  version - standard pub.dev convention, keep it up to date on every
  release.
- **This file (`docs/DECISIONS.md`)**: *why* a non-obvious choice was made,
  especially anything that required reading upstream source code rather
  than being derivable from this repo's own code. Add a new dated section
  rather than editing history away, so the reasoning trail survives even
  if the decision is later reversed.
- When re-validating against upstream after this SDKs update (they will -
  all 4 repos had commits within 24h of this document being written): a
  `gh api repos/youversion/platform-sdk-kotlin/git/trees/HEAD?recursive=true`
  diff against the file list already referenced in doc comments across
  `lib/src/**` is the fastest way to spot new/renamed/removed endpoints.
