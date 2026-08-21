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

Future UI/reader layers, if built, would live as sibling packages
(`youversion_platform_ui`, `youversion_platform_reader`), matching how the
official SDKs split `platform-core` from `platform-ui`/`platform-reader`.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`docs/DECISIONS.md`](docs/DECISIONS.md).

## License

Apache 2.0 - see [`LICENSE`](LICENSE).
