# youversion_platform_reader

Unofficial **Flutter** full Bible-reading screen for the [YouVersion Platform](https://developers.youversion.com):
passage view with text selection, chapter navigation (crossing book
boundaries and book intros), highlight creation (with an offline queue that
replays after sign-in), and font/theme settings.

Builds on [`youversion_platform_ui`](../youversion_platform_ui) (widgets)
and [`youversion_platform_core`](../youversion_platform_core) (API clients)
- every client is injected, this package owns no network/auth logic beyond
wiring them together.

No offline content cache/download - the reader only persists the last-read
reference and settings via `YouVersionReaderStorage`; caching passage
content for offline reading, if wanted, is the host app's responsibility.

Not affiliated with, endorsed by, or maintained by YouVersion/Life.Church.

Repo: <https://github.com/samuelalvesg/youversion-platform-sdk-dart>

## Installation

```yaml
dependencies:
  youversion_platform_reader: ^0.1.0
  youversion_platform_core: ^0.2.0
```

## Usage

```dart
final content = YouVersionContentClient(appKey: appKey);
final bible = await content.getBible(111);
final index = await content.getIndex(111);

BibleReader(
  content: content,
  bible: bible,
  index: index,
  initialChapterId: 'JHN.3',
  storage: mySharedPreferencesReaderStorage, // implements YouVersionReaderStorage
  highlightsClient: YouVersionHighlightsClient(appKey: appKey),
  userAccessToken: signedInToken?.accessToken,
  onSignInRequested: () => startYouVersionSignIn(),
)
```

`storage` implements `YouVersionReaderStorage` (`getString`/`setString`) -
see the class doc comment for a `shared_preferences`-backed example.

## Pending highlights

If `userAccessToken` is `null` when a highlight color is picked, the
request is queued (`PendingHighlightQueue`, persisted via `storage`) instead
of sent immediately, and replayed automatically the next time `BibleReader`
is rebuilt with a non-null `userAccessToken`.

## License

Apache 2.0 - see [`LICENSE`](LICENSE).
