# youversion-platform-sdk-dart

Unofficial **Dart** and **Flutter** SDK for the [YouVersion Platform](https://developers.youversion.com)
APIs (Bible content, OAuth Sign-In, Highlights, VOTD). Pure Dart package,
works in Flutter apps, plain Dart CLI tools, or server-side Dart. Monorepo,
mirroring the layout of the official SDK repos (`platform-sdk-kotlin`,
`-swift`, `-react`, `-reactnative-expo`): one repo, multiple published
packages under `packages/`.

Not affiliated with, endorsed by, or maintained by YouVersion/Life.Church.

Repo: <https://github.com/samuelalvesg/youversion-platform-sdk-dart>

## Packages

| Package | Path | Status |
|---|---|---|
| `youversion_platform_core` | [`packages/youversion_platform_core`](packages/youversion_platform_core) | Content, Sign-In (OAuth PKCE), Data Exchange, Highlights, Languages, Organizations, VOTD - equivalent to the official `platform-core` module |
| `youversion_platform_ui` | [`packages/youversion_platform_ui`](packages/youversion_platform_ui) | Flutter widgets (sign-in button, Bible/VOTD cards, pickers, verse actions) - equivalent to `platform-ui` |
| `youversion_platform_reader` | [`packages/youversion_platform_reader`](packages/youversion_platform_reader) | Flutter full Bible-reading screen - equivalent to `platform-reader` |

`_ui`/`_reader` are pre-release (`0.2.0`, not yet published to pub.dev,
depend on `_core` via local `path:`) - see `docs/DECISIONS.md` for the
3-package split rationale.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`docs/DECISIONS.md`](docs/DECISIONS.md).

## License

Apache 2.0 - see [`LICENSE`](LICENSE).
