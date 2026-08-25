import 'reader_theme.dart';

/// Reading font/spacing/theme preferences, persisted via
/// [ReaderSettingsStorage].
///
/// The original official-reader presets (`ReaderFontSettings.kt`, Kotlin)
/// are sizes `[9, 12, 15, 18, 21, 24]`, line-height multipliers
/// `[1.2, 1.5, 1.8]` - both lists below extend that range (more granular
/// sizes, line-height up to 2.5) rather than replacing it, so a value
/// saved under the original preset set still round-trips fine. Font
/// family is never one of these presets - it's injected via
/// [ReaderFontSettings.fontFamily] (or left `null` for the system font),
/// matching this package's font-by-injection-not-bundle principle.
class ReaderFontSettings {
  const ReaderFontSettings({
    this.fontSize = 15,
    this.lineHeight = 1.5,
    this.fontFamily,
    this.theme = ReaderTheme.pureWhite,
  });

  static const List<double> availableFontSizes = [9, 10, 12, 14, 15, 16, 18, 20, 21, 24, 28, 32];
  static const List<double> availableLineHeights = [1.0, 1.2, 1.35, 1.5, 1.65, 1.8, 2.0, 2.25, 2.5];

  final double fontSize;
  final double lineHeight;
  final String? fontFamily;
  final ReaderTheme theme;

  /// The next-smaller preset in [availableFontSizes], or [fontSize]
  /// unchanged if already at the smallest - no wraparound. Mirrors
  /// Kotlin's `ReaderFontSettings.kt` smaller/bigger buttons.
  double get nextSmallerFontSize => _step(availableFontSizes, fontSize, -1);

  /// The next-larger preset in [availableFontSizes], or [fontSize]
  /// unchanged if already at the largest - no wraparound.
  double get nextLargerFontSize => _step(availableFontSizes, fontSize, 1);

  static double _step(List<double> presets, double current, int direction) {
    final index = presets.indexOf(current);
    final nextIndex = (index == -1 ? presets.indexWhere((p) => p >= current) : index) + direction;
    if (nextIndex < 0 || nextIndex >= presets.length) return current;
    return presets[nextIndex];
  }

  ReaderFontSettings copyWith({
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    ReaderTheme? theme,
  }) {
    return ReaderFontSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toJson() => {
        'font_size': fontSize,
        'line_height': lineHeight,
        'font_family': fontFamily,
        'theme': theme.name,
      };

  factory ReaderFontSettings.fromJson(Map<String, dynamic> json) {
    return ReaderFontSettings(
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 15,
      lineHeight: (json['line_height'] as num?)?.toDouble() ?? 1.5,
      fontFamily: json['font_family'] as String?,
      theme: ReaderTheme.fromName(json['theme'] as String?),
    );
  }
}
