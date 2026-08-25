import 'package:flutter/material.dart';

/// One of the reading-canvas color presets the official readers offer,
/// distinct from a plain light/dark switch (e.g. Sepia/Cream are light
/// themes with a warm tint, not a dark-mode variant).
///
/// The first 7 values (`pureWhite`, `sepia`, `paperGray`, `cream` = light;
/// `charcoal`, `midnightBlue`, `trueBlack` = dark) match Kotlin's
/// `ReaderThemes.kt` exactly. `mint`/`skyBlue`/`graphite`/`forestNight` are
/// an intentional extension beyond that official set (see
/// docs/DECISIONS.md in bible_with_me) - not present in any of the 3 SDKs
/// with public source, so treat them as this SDK's own presets, not a
/// parity claim. Names ship English-only for now either way, no verified
/// translation exists for the original 7.
enum ReaderTheme {
  pureWhite(background: Color(0xFFFFFFFF), foreground: Color(0xFF121212), isDark: false),
  sepia(background: Color(0xFFF6EFEE), foreground: Color(0xFF121212), isDark: false),
  paperGray(background: Color(0xFFEDEFEF), foreground: Color(0xFF121212), isDark: false),
  cream(background: Color(0xFFFEF5EB), foreground: Color(0xFF121212), isDark: false),
  mint(background: Color(0xFFEAF4EC), foreground: Color(0xFF121212), isDark: false),
  skyBlue(background: Color(0xFFE9F2FA), foreground: Color(0xFF121212), isDark: false),
  charcoal(background: Color(0xFF2B3031), foreground: Colors.white, isDark: true),
  midnightBlue(background: Color(0xFF1C2A3B), foreground: Colors.white, isDark: true),
  trueBlack(background: Color(0xFF121212), foreground: Colors.white, isDark: true),
  graphite(background: Color(0xFF3A3A3A), foreground: Colors.white, isDark: true),
  forestNight(background: Color(0xFF1B2B22), foreground: Colors.white, isDark: true);

  const ReaderTheme({required this.background, required this.foreground, required this.isDark});

  final Color background;
  final Color foreground;
  final bool isDark;

  static ReaderTheme fromName(String? name) {
    return ReaderTheme.values.firstWhere((theme) => theme.name == name, orElse: () => ReaderTheme.pureWhite);
  }
}
