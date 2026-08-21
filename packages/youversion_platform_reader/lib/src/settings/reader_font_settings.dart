/// Reading font/spacing preferences, persisted via [ReaderSettingsStorage].
///
/// Sizes/spacings match the official readers' font-size setting
/// (`ReaderFontSettings.kt`, Kotlin): sizes `[9, 12, 15, 18, 21, 24]`,
/// line-height multipliers `[1.2, 1.5, 1.8]`. Font family is never one of
/// these presets - it's injected via [ReaderFontSettings.fontFamily] (or
/// left `null` for the system font), matching this package's
/// font-by-injection-not-bundle principle.
class ReaderFontSettings {
  const ReaderFontSettings({
    this.fontSize = 15,
    this.lineHeight = 1.5,
    this.fontFamily,
    this.darkMode = false,
  });

  static const List<double> availableFontSizes = [9, 12, 15, 18, 21, 24];
  static const List<double> availableLineHeights = [1.2, 1.5, 1.8];

  final double fontSize;
  final double lineHeight;
  final String? fontFamily;
  final bool darkMode;

  ReaderFontSettings copyWith({
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    bool? darkMode,
  }) {
    return ReaderFontSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'font_size': fontSize,
        'line_height': lineHeight,
        'font_family': fontFamily,
        'dark_mode': darkMode,
      };

  factory ReaderFontSettings.fromJson(Map<String, dynamic> json) {
    return ReaderFontSettings(
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 15,
      lineHeight: (json['line_height'] as num?)?.toDouble() ?? 1.5,
      fontFamily: json['font_family'] as String?,
      darkMode: json['dark_mode'] as bool? ?? false,
    );
  }
}
