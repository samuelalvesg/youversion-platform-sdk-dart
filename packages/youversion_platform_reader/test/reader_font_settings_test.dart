import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';

void main() {
  group('nextSmallerFontSize / nextLargerFontSize', () {
    test('steps to the adjacent preset', () {
      const settings = ReaderFontSettings(fontSize: 15);
      expect(settings.nextSmallerFontSize, 12);
      expect(settings.nextLargerFontSize, 18);
    });

    test('does not wrap past the smallest preset', () {
      const settings = ReaderFontSettings(fontSize: 9);
      expect(settings.nextSmallerFontSize, 9);
    });

    test('does not wrap past the largest preset', () {
      const settings = ReaderFontSettings(fontSize: 24);
      expect(settings.nextLargerFontSize, 24);
    });

    test('a non-preset size snaps to the nearest preset boundary', () {
      const settings = ReaderFontSettings(fontSize: 16);
      expect(settings.nextSmallerFontSize, 15);
      expect(settings.nextLargerFontSize, 21);
    });
  });

  test('toJson/fromJson round-trips theme by name', () {
    const settings = ReaderFontSettings(fontSize: 21, lineHeight: 1.8, theme: ReaderTheme.sepia);
    final restored = ReaderFontSettings.fromJson(settings.toJson());
    expect(restored.fontSize, 21);
    expect(restored.lineHeight, 1.8);
    expect(restored.theme, ReaderTheme.sepia);
  });

  test('fromJson defaults theme to pureWhite when missing (pre-theme-picker persisted settings)', () {
    final restored = ReaderFontSettings.fromJson({'font_size': 18, 'line_height': 1.5});
    expect(restored.theme, ReaderTheme.pureWhite);
  });
}
