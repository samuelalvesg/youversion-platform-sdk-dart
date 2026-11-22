---
name: verify-delivery
description: Runs the delivery gate of the YouVersion Platform SDK monorepo (dart analyze and dart test in core; flutter analyze and flutter test in ui and reader; pub publish dry run) and reports PASS, FAIL or NÃO EXECUTADO per command. Use before handing off to @qa-engineer or @reviewer, before marking a PR ready, and whenever someone asks whether it is green.
---

# Verify delivery (youversion-platform-sdk-dart)

## Rules
- Detect capability first: `command -v dart flutter`. Missing tool →
  `NÃO EXECUTADO: <tool> ausente`; never report green.
- The repository has no CI workflow, so this local run is the only evidence.
- Run only the packages the diff touched; `youversion_platform_reader` depends
  on `core` and `ui` through `path:`, so a change in either also runs reader.
- Never skip, weaken or delete a test to get green.
- While fixing, re-run only the failing test file.
- Keep only failures, totals and skip lines.

## Commands (per package, from `packages/<name>/`)
**`youversion_platform_core`** (pure Dart)
1. `dart pub get`
2. `dart analyze` (no issues on 2026-11-22)
3. `dart test` (84 passed on 2026-11-22)

**`youversion_platform_ui` and `youversion_platform_reader`** (Flutter)
1. `flutter pub get`
2. `flutter analyze`. Baseline with Flutter 3.44, 2026-11-22: ui 1 issue,
   reader 2 (`invalid_dependency`: publishable package with `path:`
   dependencies); only new issues count. The "need to be translated" lines are
   l10n notices, not issues.
3. `flutter test` (ui 42 passed, reader 35 passed on 2026-11-22)
4. `flutter pub get` and `flutter analyze` regenerate the tracked files
   `lib/src/l10n/*_localizations.dart`. That is generator noise: before
   committing, `git checkout -- packages/*/lib/src/l10n/` unless the change
   is intended.

`dart format` is not a gate here: on 2026-11-22 33 files of core were not
formatted. Format only the files the change touches.

## Before a release (never publish for real without the user's confirmation)
`dart pub publish --dry-run` in the package; report the output. Publishing is
irreversible (the name and every version stay reserved).

## Report (same block in the PR body)
```
VERIFY: youversion-platform-sdk-dart @ <short sha>
<package>: analyze PASS|FAIL (<n> issues), test PASS|FAIL (<passed>/<failed>/<skipped>)
NÃO EXECUTADO: <motivo> (when a tool or package was not run)
```
