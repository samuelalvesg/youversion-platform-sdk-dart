import 'package:flutter/material.dart';

/// One of the reading-canvas color presets the official readers offer,
/// distinct from a plain light/dark switch (e.g. Sepia/Cream are light
/// themes with a warm tint, not a dark-mode variant).
///
/// Values match Kotlin's `ReaderThemes.kt` exactly (`PureWhite`, `Sepia`,
/// `PaperGray`, `Cream` = light; `Charcoal`, `MidnightBlue`, `TrueBlack` =
/// dark) - names ship English-only for now, no verified translation exists
/// in any of the 3 SDKs with public source (see `docs/DECISIONS.md`).
enum ReaderTheme {
  pureWhite(background: Color(0xFFFFFFFF), foreground: Color(0xFF121212), isDark: false),
  sepia(background: Color(0xFFF6EFEE), foreground: Color(0xFF121212), isDark: false),
  paperGray(background: Color(0xFFEDEFEF), foreground: Color(0xFF121212), isDark: false),
  cream(background: Color(0xFFFEF5EB), foreground: Color(0xFF121212), isDark: false),
  charcoal(background: Color(0xFF2B3031), foreground: Colors.white, isDark: true),
  midnightBlue(background: Color(0xFF1C2A3B), foreground: Colors.white, isDark: true),
  trueBlack(background: Color(0xFF121212), foreground: Colors.white, isDark: true);

  const ReaderTheme({required this.background, required this.foreground, required this.isDark});

  final Color background;
  final Color foreground;
  final bool isDark;

  static ReaderTheme fromName(String? name) {
    return ReaderTheme.values.firstWhere((theme) => theme.name == name, orElse: () => ReaderTheme.pureWhite);
  }
}
