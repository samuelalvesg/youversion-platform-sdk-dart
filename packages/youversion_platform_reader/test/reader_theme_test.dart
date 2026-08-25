import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';

void main() {
  test('7 presets, 4 light + 3 dark, matching Kotlin ReaderThemes.kt', () {
    expect(ReaderTheme.values, hasLength(7));
    expect(ReaderTheme.values.where((t) => !t.isDark), [
      ReaderTheme.pureWhite,
      ReaderTheme.sepia,
      ReaderTheme.paperGray,
      ReaderTheme.cream,
    ]);
    expect(ReaderTheme.values.where((t) => t.isDark), [
      ReaderTheme.charcoal,
      ReaderTheme.midnightBlue,
      ReaderTheme.trueBlack,
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
