# youversion_platform_reader

Unofficial **Flutter** full Bible-reading screen for the [YouVersion Platform](https://developers.youversion.com):
passage view with tap-to-select-a-verse, chapter navigation (crossing book
boundaries and book intros), highlight creation (with an offline queue that
replays after sign-in), and a 7-theme reading font/theme settings sheet.

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
  youversion_platform_reader: ^0.3.0
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

## Verse selection and highlights

Tapping any word of a verse selects that whole verse (dashed underline +
tint), not free-text selection, and opens `VerseActionSheet` scoped to
that exact verse - highlights are created/removed against the tapped
verse's own USFM id (e.g. `JHN.3.16`), not the whole chapter. Existing
highlights for the loaded chapter are fetched automatically (via
`YouVersionHighlightsClient.listHighlights`) whenever `userAccessToken` is
set, so they render immediately without waiting for a fresh tap.

## Reading theme

`ReaderFontSettings.theme` (`ReaderTheme`) picks one of 7 presets -
`pureWhite`/`sepia`/`paperGray`/`cream` (light), `charcoal`/`midnightBlue`/
`trueBlack` (dark) - offered in `FontSettingsSheet`'s theme picker.
`BibleReader` applies the chosen theme's background/text color and the
chosen font size/line-height/family to its own subtree automatically.

## Localization

Same as `youversion_platform_ui`: works in English with no host setup, and
picks up localized strings when you register the generated delegate:

```dart
MaterialApp(
  localizationsDelegates: YouVersionReaderLocalizations.localizationsDelegates,
  supportedLocales: YouVersionReaderLocalizations.supportedLocales,
  // ...
)
```

## Example

[`example/`](example) is the **full SDK demo app** - not just this
package, every `youversion_platform_core` client (Content, Sign-In, Data
Exchange, Highlights, Languages, Organizations, VOTD) and every
sign-in/reading widget from `youversion_platform_ui`/
`youversion_platform_reader`, with real OAuth sign-in and persistent
storage (`shared_preferences`). `youversion_platform_ui`'s own example
stays a static, network-free widget gallery - this is the real one.

Needs a real App Key (get one free at
[developers.youversion.com](https://developers.youversion.com)):

```sh
cd example
flutter run --dart-define=APP_KEY=your-key-here
```

Sign-in uses the app's own registered redirect URI (not a deep link this
example captures itself) - after approving in the browser, paste the
resulting URL back into the app. This is a demo simplification (see
`sign_in_page.dart`'s doc comment) - a real app registers its own deep
link/App Link and skips that step.

## License

Apache 2.0 - see [`LICENSE`](LICENSE).
