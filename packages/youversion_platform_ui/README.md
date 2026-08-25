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
  youversion_platform_ui: ^0.3.0
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

## Bible text rendering

`BibleTextView` parses YouVersion's passage HTML ("YVDOM") - verse
numbers, words-of-Christ (red-letter) styling, inline footnote markers,
section headings - and supports tap-to-select-a-verse:

```dart
BibleTextView(
  content: passage.content,
  chapterId: 'JHN.3', // omit for a display-only passage with no verse identity
  selectedVerseId: selectedVerseId,
  highlightsByVerseId: highlightsByVerseId, // {'JHN.3.16': 'fffe00', ...}
  isRightToLeft: bible.isRightToLeft,
  onVerseTap: (verseId) => setState(() => selectedVerseId = verseId),
)
```

`BibleCard`/`VerseOfTheDayCard` use this internally for their content, with
no `chapterId` (display-only, no verse identity).

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

## Localization

Every widget works out of the box in English, with no host setup required.
To get localized strings (13 locales beyond English - `af`, `ar`, `cs`,
`cy`, `de`, `es`, `fr`, `ko`, `no`, `pt`, `tr`, `vi`, `zh`), register the
generated delegate in your `MaterialApp`:

```dart
MaterialApp(
  localizationsDelegates: YouVersionUiLocalizations.localizationsDelegates,
  supportedLocales: YouVersionUiLocalizations.supportedLocales,
  // ...
)
```

Combine `localizationsDelegates`/`supportedLocales` with your own app's
lists (e.g. via `...`) if you have other localized packages too.

RTL layout (Arabic) also depends on this: Flutter derives the ambient
`Directionality` from `MaterialApp`'s resolved locale, which only happens
once `supportedLocales` includes `ar`. Without registering the delegate,
every widget renders left-to-right regardless of device locale.

## Example

A runnable example app is at [`example/`](example) - `cd example && flutter run`.
No App Key needed (every widget shown uses hand-written sample data, not a
real network response) - a static, network-free widget gallery.

For a real, end-to-end demo (every `youversion_platform_core` endpoint,
real sign-in, persistent storage), see
[`youversion_platform_reader`'s example](../youversion_platform_reader/example).

## License

Apache 2.0 - see [`LICENSE`](LICENSE).
