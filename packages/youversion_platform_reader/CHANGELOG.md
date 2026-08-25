## Unreleased

- Added `ReadingThemeScope` (public, exported) - extracted from
  `BibleReader.build()` so other widgets rendering scripture can apply
  the same reading theme without duplicating the `ThemeData` construction.
- Added `BibleReader.onCopyVerse`/`onShareVerse`. **Fixed a real bug**:
  `VerseActionSheet`'s `onCopy`/`onShare` were never actually wired by
  `BibleReader` - copy/share have never worked. Also relaxed the
  verse-action sheet's early-return so it still opens for copy/share even
  without a `highlightsClient` configured. See `docs/DECISIONS.md`.

- **Fixed a real bug** (confirmed live, "infinite loading" report):
  `BibleReader._loadChapter` had no error handling around the passage/
  highlights fetch, so any exception there (e.g. the `Highlight.id`
  null-cast crash fixed in `youversion_platform_core`) left `isLoading`
  stuck `true` forever. Now wraps the load in try/catch/finally and shows
  a retry UI on failure instead of hanging silently.
- **Fixed a real bug** (confirmed live, "all buttons wrong color in dark
  theme"): the reading-theme override built its `ThemeData` via
  `.copyWith(colorScheme: ...)` on the ambient theme, which doesn't
  recompute already-resolved derived component themes (button themes
  among them). Now constructs a fresh `ThemeData(colorScheme: ...)`
  instead, so every component theme derives consistently. See
  `docs/DECISIONS.md`.
- `BibleReader`'s built-in load-error UI now shows a human-readable
  message per `YouVersionErrorReason` instead of the raw
  `YouVersionException(...).toString()`, disables/counts down its retry
  button for the real `retryAfter` window on a `429` instead of inviting
  another guaranteed-to-fail tap, and scrolls instead of overflowing when
  embedded in a height-constrained area (confirmed live, "RenderFlex
  overflowed"). See `docs/DECISIONS.md`.
- **Fixed a real bug** (confirmed live, part of a "mixed English/
  Portuguese text" report): those 5 load-error messages were hardcoded
  English literals, bypassing `youVersionReaderStringsOf` even though the
  rest of the widget uses it - added `rateLimitedError`/
  `signInRequiredError`/`notPermittedError`/`invalidResponseError`/
  `loadFailedError`. See `docs/DECISIONS.md`.

## 0.3.0

Reading theme picker, verse tap-to-select, and per-verse highlight
identity - closes the gaps found in the 2026-08-24 sweep against Kotlin
(see `docs/DECISIONS.md`).

- **Breaking**: `ReaderFontSettings.darkMode` (`bool`) replaced by
  `ReaderFontSettings.theme` (`ReaderTheme`) - a full 7-preset reading
  theme, not just light/dark (values match Kotlin's `ReaderThemes.kt`
  exactly: `pureWhite`/`sepia`/`paperGray`/`cream` light,
  `charcoal`/`midnightBlue`/`trueBlack` dark). `BibleReader` now actually
  applies the chosen theme (background + text color) and font
  size/line-height/family to its subtree - previously these were
  persisted but silently never applied, a pre-existing dead-wiring bug.
- Added `ReaderFontSettings.nextSmallerFontSize`/`nextLargerFontSize`
  (Kotlin-style step helpers) and matching "A-"/"A+" buttons in
  `FontSettingsSheet`, alongside the existing size `ChoiceChip`s (both
  stay - not a replacement).
- `BibleReaderController` gained `selectedVerseId` and `verseHighlights`
  (a full per-verse highlight map for the loaded chapter, fetched via
  `YouVersionHighlightsClient.listHighlights` when signed in) -
  `BibleReader` now highlights/creates highlights by the actual tapped
  verse's USFM id, not the whole chapter id (a pre-existing identity bug:
  every highlight used to mark the entire chapter). `VerseActionSheet`'s
  `onRemoveHighlight` is now wired to `deleteHighlight`, previously unwired.
- Verse selection is tap-a-verse now, not long-press-anywhere - matches
  `youversion_platform_ui` 0.3.0's new `BibleTextView` tap model.
- **Fixed a real bug** (confirmed live against the API): `ChapterNavigation`
  and `ReferencesScreen`'s "Intro" chip both hardcoded a book's intro
  passage id as `'GEN.intro'` (lowercase) instead of reading the real id
  the API returns (`'GEN.INTRO'`, uppercase) - the old string 404s.
  `ChapterNavigation.next` also gained the ability to navigate forward
  from an intro to chapter 1 (previously only `previous` treated the intro
  as a boundary at all). See `docs/DECISIONS.md`.
- Footnote taps now open a bottom sheet with the note text (`BibleReader`
  wires `youversion_platform_ui` 0.3.0's new `onFootnoteTap`).
- Added `example/` - `cd example && flutter run`, needs a real App Key
  (see README).

## 0.2.0

Adds i18n, mirroring `youversion_platform_ui` 0.2.0: `YouVersionReaderLocalizations`
(generated via `gen-l10n`) covers the same 13 non-English locales for the one
shared string (`searchBooksHint`, reused from React's `searchPlaceholder`).
The reader-specific strings (font settings, dark mode, "Intro") have no
upstream equivalent to reuse and ship English-only for now; see
`docs/DECISIONS.md`. Zero-config via `youVersionReaderStringsOf(context)`,
same fallback-to-English-when-unregistered behavior as `_ui`.

## 0.1.0

Initial release. `BibleReader` full reading screen, `ChapterNavigation`
(prev/next crossing book boundaries + book intros), `PendingHighlightQueue`
(offline-queued highlight requests, replayed on sign-in), `ReaderFontSettings`
+ `ReaderSettingsStorage`, `YouVersionReaderStorage`, `ReferencesScreen`,
`FontSettingsSheet`.
