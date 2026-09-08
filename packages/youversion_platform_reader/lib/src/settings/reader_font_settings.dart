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
    this.bionicReading = false,
    this.bionicBoldFraction = 1 / 3,
  });

  static const List<double> availableFontSizes = [9, 10, 12, 14, 15, 16, 18, 20, 21, 24, 28, 32];
  static const List<double> availableLineHeights = [1.0, 1.2, 1.35, 1.5, 1.65, 1.8, 2.0, 2.25, 2.5];

  final double fontSize;
  final double lineHeight;
  final String? fontFamily;
  final ReaderTheme theme;

  /// Bolds the leading portion of each word's letters to give the eye a
  /// fixation point, a real accessibility/reading-speed aid (not in any
  /// of the 3 official SDKs, same kind of intentional extension as the
  /// extra [ReaderTheme] presets). [BibleTextView] does the actual
  /// per-word span splitting; this field is just the saved on/off
  /// preference - how MUCH of each word gets bolded is
  /// [bionicBoldFraction], separate from this toggle.
  ///
  /// Deliberately NOT named/labelled "Bionic Reading" anywhere user-facing
  /// (see `bionicReadingLabel` in the `.arb`s, changed 2026-09-08) - that
  /// term is a registered trademark (BRCG Casutt GmbH, US/EU/CH/CA/JP/AU/
  /// NZ/UK/LI) for a commercial product with its own patent (granted in
  /// France, FR1755215 - the fixed emphasis fractions it claims in its
  /// preferred embodiments are 2/5 and 3/5 of a word's leading characters,
  /// or a fixed 3-character prefix for longer words). The Dart identifier
  /// here keeps the internal name (just an implementation detail, not
  /// user-facing/marketing) but [bionicBoldFraction]'s default (`1/3`,
  /// `0.333...`) was chosen specifically to sit OUTSIDE those claimed
  /// fixed fractions, not copy them - this is engineering due diligence,
  /// not legal advice; consult a lawyer before shipping this feature
  /// commercially in a jurisdiction with a granted patent (France, as far
  /// as could be confirmed from the rights holder's own public IP page).
  final bool bionicReading;

  /// Fraction (`0.0`-`1.0`) of each word's leading characters that gets
  /// bolded when [bionicReading] is on - `ceil(word.length * fraction)`,
  /// clamped to at least 1 for any non-empty word (see
  /// `BibleTextView._bionicSpans`). Default `1/3` - see the patent-
  /// avoidance note on [bionicReading] for why this specific value.
  /// Adjustable (2026-09-08 ask) via a slider in [FontSettingsSheet],
  /// same "aplica na hora" pattern as font size/line height.
  final double bionicBoldFraction;

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
    bool? bionicReading,
    double? bionicBoldFraction,
  }) {
    return ReaderFontSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      theme: theme ?? this.theme,
      bionicReading: bionicReading ?? this.bionicReading,
      bionicBoldFraction: bionicBoldFraction ?? this.bionicBoldFraction,
    );
  }

  Map<String, dynamic> toJson() => {
        'font_size': fontSize,
        'line_height': lineHeight,
        'font_family': fontFamily,
        'theme': theme.name,
        'bionic_reading': bionicReading,
        'bionic_bold_fraction': bionicBoldFraction,
      };

  factory ReaderFontSettings.fromJson(Map<String, dynamic> json) {
    return ReaderFontSettings(
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 15,
      lineHeight: (json['line_height'] as num?)?.toDouble() ?? 1.5,
      fontFamily: json['font_family'] as String?,
      theme: ReaderTheme.fromName(json['theme'] as String?),
      bionicReading: json['bionic_reading'] as bool? ?? false,
      // `?? (1 / 3)` (não só o default do construtor) - JSON salvo ANTES
      // deste campo existir não tem a chave, `as num?` já cobre isso
      // sozinho, mas explícito aqui deixa claro que é intencional (versão
      // antiga do app = mesmo comportamento de hoje, não `0`/negrito
      // vazio).
      bionicBoldFraction: (json['bionic_bold_fraction'] as num?)?.toDouble() ?? (1 / 3),
    );
  }
}
