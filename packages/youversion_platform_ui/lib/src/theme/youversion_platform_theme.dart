import 'package:flutter/material.dart';

import 'bible_text_theme.dart';
import 'reader_color_scheme.dart';

/// Base [ThemeData] factory for apps embedding YouVersion Platform widgets.
///
/// Not required - every widget in this package also works with a plain
/// Material [ThemeData] via `Theme.of(context)`. This factory only wires up
/// the two [ThemeExtension]s ([BibleTextTheme], [ReaderColorScheme]) with
/// sensible defaults, the same way apps typically build a seeded
/// [ColorScheme] and hand it to [ThemeData].
abstract final class YouVersionPlatformTheme {
  static ThemeData light({Color seedColor = const Color(0xFF3A5CED), String? fontFamily}) {
    final colorScheme = ColorScheme.fromSeed(seedColor: seedColor);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      extensions: [
        BibleTextTheme.fallback(fontFamily: fontFamily),
        ReaderColorScheme.light(colorScheme),
      ],
    );
  }

  static ThemeData dark({Color seedColor = const Color(0xFF3A5CED), String? fontFamily}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      extensions: [
        BibleTextTheme.fallback(fontFamily: fontFamily),
        ReaderColorScheme.dark(colorScheme),
      ],
    );
  }
}
