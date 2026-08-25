## Unreleased

- Right-clicking a verse (`onSecondaryTapUp`) now also fires
  `onVerseLongPress` - a desktop-native alternative to press-and-hold for
  opening the same context menu, on the same `TapGestureRecognizer`
  already used for tap/long-press (no extra recognizer needed).

- **Breaking**: `BibleTextView.selectedVerseId` (`String?`) replaced by
  `selectedVerseIds` (`Set<String>`) - supports multi-select (tap several
  verses, act on all of them). Added `onVerseLongPress`, separate from
  `onVerseTap`, so a caller can use tap for select/deselect and
  long-press for "act on the current selection" (matches the official
  YouVersion app's verse-selection model). See `docs/DECISIONS.md` for
  why long-press needed a hand-rolled `TapGestureRecognizer`-based
  helper (`verseTapLongPressRecognizer`) rather than a custom
  `GestureRecognizer` subclass - `RenderParagraph`'s semantics-tree
  assembly only supports Flutter's own recognizer types on a `TextSpan`.

- Added `extractVersePlainText` (public, exported) - one verse's plain
  text out of a passage's YVDOM `content`, for copy/share actions that
  want plain text rather than HTML.

- Added `BibleTextView.scrollToVerseId` - scrolls the given verse into
  view once (`Scrollable.ensureVisible`), for opening a chapter already
  focused on a specific verse.
- **Fixed a real bug** (confirmed live, part of a "mixed English/
  Portuguese text" report): `BibleVersionPicker`'s no-title/no-abbreviation
  fallback label (`'Bible ${bible.id}'`) was hardcoded English, bypassing
  `youVersionUiStringsOf` - added `bibleIdFallbackLabel` instead. See
  `docs/DECISIONS.md`.

## 0.3.0

`BibleTextView` is now a real renderer, not a regex tag-stripper.

- **Breaking**: `BibleTextView` gained a `chapterId` parameter (nullable -
  omit it for a display-only passage with no verse identity, e.g.
  `BibleCard`/`VerseOfTheDayCard`), `selectedVerseId`,
  `highlightsByVerseId`, and `isRightToLeft`. `onVerseTap` (previously
  accepted but never invoked) now actually fires on tap.
- Parses the passage HTML ("YVDOM") YouVersion's API actually returns -
  verse numbers, words-of-Christ (red-letter) styling, inline footnote
  markers, section headings - via a new pure-Dart parser
  (`rendering/bible_text_node.dart`, `package:html`-based). Verified
  against real `GET /v1/bibles/{id}/passages/{id}?format=html` responses,
  not just paraphrased fixtures - see `docs/DECISIONS.md`.
- Tap-to-select-a-verse: tapping any word of a verse selects that whole
  verse (dashed underline + a lighter highlight tint), not free-text
  selection. This is this package's own product decision, not matched by
  any of the 4 official SDKs (React/Kotlin both use a solid underline for
  their equivalent state) - see `docs/DECISIONS.md`.
- `ReaderColorScheme.wordsOfChrist` (already existed) is now actually
  wired into rendering.
- Added `HighlightColors`-based `Semantics` labels (`highlightColorsLabel`
  group label + per-color labels) on `VerseActionSheet`'s swatches.
- `BibleTextView` gained `onFootnoteTap` (its own tap target, separate
  from verse selection) and poetry-line formatting (`.q1`-`.q4`/`.qc`/
  `.qs`, a line break per line) - see `docs/DECISIONS.md`.
- Added `example/` - `cd example && flutter run`, no App Key needed.
- `BibleTextTheme.fallback` gained an optional `color` parameter. Fixes a
  real bug found by live-testing `youversion_platform_reader`'s example
  app: `ThemeData.copyWith(colorScheme: ...)` doesn't recolor an
  already-resolved `textTheme`, so scripture text relying on ambient
  inheritance could end up dark-on-dark/light-on-light when a host app's
  reading theme brightness didn't match its own ambient theme - see
  `docs/DECISIONS.md`.
- **Breaking**: `VerseActionSheet` is now a `StatefulWidget` (keeps its own
  local copy of `selectedColor`, still calling `onColorSelected`/
  `onRemoveHighlight` the same as before) - fixes another bug found live:
  `showModalBottomSheet`'s `builder` isn't re-invoked just because the
  caller's state changes elsewhere, so the swatch selection ring never
  visually updated on tap. Only breaking if a caller extended/instantiated
  the old `StatelessWidget` type directly rather than just using the
  widget - the public constructor/props are unchanged.

## 0.2.0

Adds i18n: widget strings are no longer English-hardcoded.

- `YouVersionUiLocalizations` (generated via Flutter's `gen-l10n`) covers
  13 locales beyond English (`af`, `ar`, `cs`, `cy`, `de`, `es`, `fr`, `ko`,
  `no`, `pt`, `tr`, `vi`, `zh`) for the strings shared with the official
  React SDK's UI package (Copy/Share/Cancel/Close/Sign out/search hints,
  etc.) - those translations are reused verbatim from
  `@youversion/platform-react-ui`'s human-reviewed locale files, not
  machine-translated. App-specific strings with no upstream equivalent
  (e.g. the sign-in-failed dialog copy) ship English-only for now; see
  `docs/DECISIONS.md`.
- Zero-config by default: widgets read strings via
  `youVersionUiStringsOf(context)`, which falls back to the bundled English
  strings when the host app hasn't registered
  `YouVersionUiLocalizations.delegate` - same principle as
  `BibleTextTheme.of`/`ReaderColorScheme.of`. Registering the delegate (see
  README) is opt-in, for apps that want localized strings.

## 0.1.0

Initial release. Theme (`YouVersionPlatformTheme`, `BibleTextTheme`,
`ReaderColorScheme`), sign-in widgets (`YouVersionSignInButton`,
`SignInPromptSheet`, `SignInErrorDialog`, `SignOutConfirmationDialog`), and
content widgets (`BibleCard`, `BibleTextView`, `VerseOfTheDayCard`,
`VerseActionSheet`, `BibleVersionPicker`, `BibleLanguagePicker`).
