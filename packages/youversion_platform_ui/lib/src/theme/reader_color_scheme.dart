import 'package:flutter/material.dart';

/// Color roles the reading UI needs that Material's [ColorScheme] doesn't
/// have a slot for: highlight overlay, "words of Christ" red-letter tint,
/// and a reading-canvas color distinct from `surface` (some Bible themes
/// use a warm off-white/near-black rather than the app's own surface tone).
///
/// Mirrors `platform-ui`'s `theme/ReaderColorScheme.kt` (Kotlin) and
/// `theme/tokens/BibleColorLightTokens.kt` / `BibleColorDarkTokens.kt`.
@immutable
class ReaderColorScheme extends ThemeExtension<ReaderColorScheme> {
  const ReaderColorScheme({
    required this.readingCanvas,
    required this.highlightBorder,
    required this.wordsOfChrist,
    required this.highlightOverlayAlpha,
  });

  factory ReaderColorScheme.light(ColorScheme colorScheme) {
    return const ReaderColorScheme(
      readingCanvas: Color(0xFFFFFDF7),
      highlightBorder: Color(0x29000000),
      wordsOfChrist: Color(0xFFC02020),
      highlightOverlayAlpha: 0.55,
    );
  }

  factory ReaderColorScheme.dark(ColorScheme colorScheme) {
    return const ReaderColorScheme(
      readingCanvas: Color(0xFF15130F),
      highlightBorder: Color(0x40FFFFFF),
      wordsOfChrist: Color(0xFFFF6B6B),
      // Highlights read as brighter against a dark canvas at full alpha,
      // so the reader dims them - matches BibleColorDarkTokens.kt.
      highlightOverlayAlpha: 0.35,
    );
  }

  final Color readingCanvas;
  final Color highlightBorder;
  final Color wordsOfChrist;
  final double highlightOverlayAlpha;

  @override
  ReaderColorScheme copyWith({
    Color? readingCanvas,
    Color? highlightBorder,
    Color? wordsOfChrist,
    double? highlightOverlayAlpha,
  }) {
    return ReaderColorScheme(
      readingCanvas: readingCanvas ?? this.readingCanvas,
      highlightBorder: highlightBorder ?? this.highlightBorder,
      wordsOfChrist: wordsOfChrist ?? this.wordsOfChrist,
      highlightOverlayAlpha: highlightOverlayAlpha ?? this.highlightOverlayAlpha,
    );
  }

  @override
  ReaderColorScheme lerp(ThemeExtension<ReaderColorScheme>? other, double t) {
    if (other is! ReaderColorScheme) return this;
    return ReaderColorScheme(
      readingCanvas: Color.lerp(readingCanvas, other.readingCanvas, t)!,
      highlightBorder: Color.lerp(highlightBorder, other.highlightBorder, t)!,
      wordsOfChrist: Color.lerp(wordsOfChrist, other.wordsOfChrist, t)!,
      highlightOverlayAlpha:
          highlightOverlayAlpha + (other.highlightOverlayAlpha - highlightOverlayAlpha) * t,
    );
  }

  /// Reads this extension from [context], falling back to
  /// [ReaderColorScheme.light]/[ReaderColorScheme.dark] by ambient
  /// brightness when the [ThemeData] doesn't declare one.
  static ReaderColorScheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ReaderColorScheme>() ??
        (theme.brightness == Brightness.dark
            ? ReaderColorScheme.dark(theme.colorScheme)
            : ReaderColorScheme.light(theme.colorScheme));
  }

  /// [highlightBorder] with [alpha] set to [highlightOverlayAlpha] for
  /// painting a highlight color's overlay (the swatch colors from
  /// `HighlightColors` are opaque; the overlay itself is drawn translucent).
  Color highlightOverlay(Color highlightColor) {
    return highlightColor.withValues(alpha: highlightOverlayAlpha);
  }
}
