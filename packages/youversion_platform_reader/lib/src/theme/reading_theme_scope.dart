import 'package:flutter/material.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

import '../settings/reader_font_settings.dart';

/// Wraps [child] in a fresh [Theme] matching [fontSettings]'s chosen
/// [ReaderTheme] (background/foreground/font) - extracted from
/// `BibleReader.build()` so any widget rendering scripture (not just
/// `BibleReader` itself) can apply the same reading theme consistently,
/// e.g. an inline chapter preview elsewhere in a host app.
///
/// A fresh `ThemeData(colorScheme: ...)`, not `ambientTheme.copyWith
/// (colorScheme: ...)` - `copyWith` only swaps the `colorScheme`
/// *reference*, it does not recompute the many component themes
/// (`textTheme`, `iconTheme`, `appBarTheme`, `filledButtonTheme`/
/// `textButtonTheme`/etc.) that `ThemeData`'s own constructor derives from
/// the color scheme at construction time. Confirmed live, repeatedly,
/// patching one slot at a time in `BibleReader` before this was extracted -
/// first scripture/plain text was unreadable, then just the AppBar back
/// button, then it turned out to be literally every button whenever the
/// reader's own chosen theme brightness didn't match the host app's
/// ambient one. Building a whole new `ThemeData` from the color scheme is
/// the actual fix Material's own API is designed for this - not a
/// slot-by-slot `copyWith` chase. See `docs/DECISIONS.md`.
class ReadingThemeScope extends StatelessWidget {
  const ReadingThemeScope({super.key, required this.fontSettings, required this.child});

  final ReaderFontSettings fontSettings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ambientTheme = Theme.of(context);
    final readerTheme = fontSettings.theme;

    final readerColors = (readerTheme.isDark
            ? ReaderColorScheme.dark(ambientTheme.colorScheme)
            : ReaderColorScheme.light(ambientTheme.colorScheme))
        .copyWith(readingCanvas: readerTheme.background);
    final bibleTextTheme =
        BibleTextTheme.fallback(fontFamily: fontSettings.fontFamily, color: readerTheme.foreground).copyWith(
      scriptureM: TextStyle(
        fontFamily: fontSettings.fontFamily,
        fontSize: fontSettings.fontSize,
        height: fontSettings.lineHeight,
        color: readerTheme.foreground,
      ),
    );

    final colorScheme = (readerTheme.isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
      surface: readerTheme.background,
      onSurface: readerTheme.foreground,
      brightness: readerTheme.isDark ? Brightness.dark : Brightness.light,
    );

    return Theme(
      data: ThemeData(
        colorScheme: colorScheme,
        brightness: readerTheme.isDark ? Brightness.dark : Brightness.light,
        extensions: [readerColors, bibleTextTheme],
      ),
      child: child,
    );
  }
}
