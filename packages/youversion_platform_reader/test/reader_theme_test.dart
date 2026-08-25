import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';

void main() {
  test('11 presets, 6 light + 5 dark - 7 matching Kotlin ReaderThemes.kt plus 4 extras', () {
    expect(ReaderTheme.values, hasLength(11));
    expect(ReaderTheme.values.where((t) => !t.isDark), [
      ReaderTheme.pureWhite,
      ReaderTheme.sepia,
      ReaderTheme.paperGray,
      ReaderTheme.cream,
      ReaderTheme.mint,
      ReaderTheme.skyBlue,
    ]);
    expect(ReaderTheme.values.where((t) => t.isDark), [
      ReaderTheme.charcoal,
      ReaderTheme.midnightBlue,
      ReaderTheme.trueBlack,
      ReaderTheme.graphite,
      ReaderTheme.forestNight,
    ]);
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
