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
