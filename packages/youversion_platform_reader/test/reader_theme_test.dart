import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';

void main() {
  test(
    '13 presets, 7 light + 6 dark - 7 matching Kotlin ReaderThemes.kt plus 6 extras '
    '(4 original + WCAG AAA pure-contrast light/dark pair)',
    () {
      expect(ReaderTheme.values, hasLength(13));
      expect(ReaderTheme.values.where((t) => !t.isDark), [
        ReaderTheme.pureWhite,
        ReaderTheme.sepia,
        ReaderTheme.paperGray,
        ReaderTheme.cream,
        ReaderTheme.mint,
        ReaderTheme.skyBlue,
        ReaderTheme.pureContrastLight,
      ]);
      expect(ReaderTheme.values.where((t) => t.isDark), [
        ReaderTheme.charcoal,
        ReaderTheme.midnightBlue,
        ReaderTheme.trueBlack,
        ReaderTheme.graphite,
        ReaderTheme.forestNight,
        ReaderTheme.pureContrastDark,
      ]);
    },
  );

  test('pureContrastLight/pureContrastDark are true pure black/white (WCAG AAA, ~21:1 contrast)', () {
    expect(ReaderTheme.pureContrastLight.background, const Color(0xFFFFFFFF));
    expect(ReaderTheme.pureContrastLight.foreground, const Color(0xFF000000));
    expect(ReaderTheme.pureContrastDark.background, const Color(0xFF000000));
    expect(ReaderTheme.pureContrastDark.foreground, const Color(0xFFFFFFFF));
  });

  test('fromName round-trips with .name', () {
    for (final theme in ReaderTheme.values) {
      expect(ReaderTheme.fromName(theme.name), theme);
    }
  });

  test('fromName falls back to pureWhite for null/unknown', () {
    expect(ReaderTheme.fromName(null), ReaderTheme.pureWhite);
    expect(ReaderTheme.fromName('not-a-theme'), ReaderTheme.pureWhite);
  });
}
