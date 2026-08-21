# youversion_platform_ui

Unofficial **Flutter** UI components for the [YouVersion Platform](https://developers.youversion.com):
sign-in button, Bible/verse-of-the-day cards, version/language pickers, and
a verse action sheet (copy/share/highlight).

No state-management dependency (no Riverpod/Provider/Bloc) - every widget
takes data and callbacks as constructor parameters. Pair with
[`youversion_platform_core`](../youversion_platform_core) for the API
clients that produce the data these widgets render; this package never
calls the network itself.

Not affiliated with, endorsed by, or maintained by YouVersion/Life.Church.

Repo: <https://github.com/samuelalvesg/youversion-platform-sdk-dart>

## Installation

```yaml
dependencies:
  youversion_platform_ui: ^0.1.0
  youversion_platform_core: ^0.2.0
```

## Theme

Optional - every widget also works with a plain `Theme.of(context)`.

```dart
MaterialApp(
  theme: YouVersionPlatformTheme.light(),
  darkTheme: YouVersionPlatformTheme.dark(),
  // ...
)
```

`YouVersionPlatformTheme` wires up two `ThemeExtension`s: `BibleTextTheme`
(reading-optimized type scale) and `ReaderColorScheme` (highlight overlay,
reading-canvas, "words of Christ" colors). Read them back with
`BibleTextTheme.of(context)` / `ReaderColorScheme.of(context)`.

## Sign-in

```dart
YouVersionSignInButton(
  onPressed: () => openYouVersionSignIn(), // your app's own launch logic,
                                            // using youversion_platform_core
  isLoading: signingIn,
)
```

## Bible / verse-of-the-day cards

```dart
BibleCard(reference: 'John 3:16', content: passage.content);

VerseOfTheDayCard(reference: 'Romans 8:28', content: passage.content);
```

## Pickers

```dart
BibleVersionPicker(bibles: bibles.data, onSelected: (bible) { ... });
BibleLanguagePicker(languages: languages.data, onSelected: (language) { ... });
```

## Verse actions

```dart
showModalBottomSheet(
  context: context,
  builder: (_) => VerseActionSheet(
    selectedColor: currentHighlight?.color,
    onColorSelected: (hex) => highlights.createHighlight(
      userAccessToken: token.accessToken,
      bibleId: bibleId,
      passageId: passageId,
      color: hex,
    ),
  ),
);
```

## License

Apache 2.0 - see [`LICENSE`](LICENSE).
