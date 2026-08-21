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
- Full planned package/file structure lives in this session's plan file
  (not repo-tracked) - re-derive or ask for it when implementation actually
  starts; this entry is the durable "why", not the file-by-file "what".
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
