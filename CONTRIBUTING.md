# Contributing

## Language

Everything in this repo - code, comments, doc comments, commit messages,
exception messages, docs - is in **English**. This is a pub.dev package
with an international audience; a non-English comment or runtime error
message is a real usability gap for most contributors/users, not a style
nit.

## Repo layout

Monorepo. Each published package lives under `packages/<name>/` with its
own `pubspec.yaml`. See [`docs/DECISIONS.md`](docs/DECISIONS.md) for why.

## Validating API contracts

This package mirrors a third-party HTTP API it doesn't control. Before
adding or changing an endpoint, prefer reading the actual source of an
official SDK over trusting `developers.youversion.com` docs alone - the
docs and the 4 official SDKs (`platform-sdk-kotlin`, `-swift`, `-react`,
`-reactnative-expo`) have been found to disagree with each other on
non-trivial details (field names, path segments, claim names). `gh api
repos/youversion/<repo>/contents/<path>` and `git/trees?recursive=true` are
the fastest way to read real source without cloning. Document which file
you validated against in the relevant doc comment (see existing code for
the pattern), and log anything genuinely ambiguous or contradictory in
[`docs/DECISIONS.md`](docs/DECISIONS.md).

## Testing

`dart test` / `dart analyze` must pass clean from
`packages/youversion_platform_core/` before a change is done. Tests mock
HTTP (`package:http/testing.dart`'s `MockClient`) - no real network calls.

## Publishing

`dart pub publish` is irreversible (the package name and every published
version stay reserved forever). Always run `dart pub publish --dry-run`
first, and get explicit confirmation before the real publish.
