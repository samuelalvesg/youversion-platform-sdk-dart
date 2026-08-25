import 'package:flutter/material.dart';

/// Reading-optimized typographic scale, separate from Material's
/// [TextTheme] since scripture needs a wider size range (accessibility
/// font-size settings go well past Material's default headline/body scale).
///
/// Mirrors `platform-ui`'s `theme/tokens/BibleTypographyTokens.kt`
/// (Kotlin): `scriptureXxl/xl/l/m/s`, `header`, `label`, `caption`. Font
/// family is injected (never bundled - see package README), defaulting to
/// the ambient [ThemeData.fontFamily] / system font when omitted.
@immutable
class BibleTextTheme extends ThemeExtension<BibleTextTheme> {
  const BibleTextTheme({
    required this.scriptureXxl,
    required this.scriptureXl,
    required this.scriptureL,
    required this.scriptureM,
    required this.scriptureS,
    required this.header,
    required this.label,
    required this.caption,
  });

  /// [color] is left `null` by default (inherits from the ambient
  /// [DefaultTextStyle]) - pass it explicitly when the caller is about to
  /// override [ThemeData.colorScheme] independently of [ThemeData.textTheme]
  /// (e.g. a reading theme that doesn't match the host app's own light/dark
  /// setting): `ThemeData.copyWith(colorScheme: ...)` does **not** recolor
  /// an already-resolved `textTheme`, so text relying on ambient
  /// inheritance can end up dark-on-dark/light-on-light in that case.
  factory BibleTextTheme.fallback({String? fontFamily, Color? color}) {
    TextStyle style(double size, {FontWeight weight = FontWeight.normal, double height = 1.5}) {
      return TextStyle(fontFamily: fontFamily, fontSize: size, fontWeight: weight, height: height, color: color);
    }

    return BibleTextTheme(
      scriptureXxl: style(24),
      scriptureXl: style(21),
      scriptureL: style(18),
      scriptureM: style(15),
      scriptureS: style(12),
      header: style(17, weight: FontWeight.w600, height: 1.2),
      label: style(13, weight: FontWeight.w500, height: 1.2),
      caption: style(11, height: 1.2),
    );
  }

  /// Same reading sizes offered in the official readers' font-size setting.
  static const List<double> readingFontSizes = [9, 12, 15, 18, 21, 24];

  final TextStyle scriptureXxl;
  final TextStyle scriptureXl;
  final TextStyle scriptureL;
  final TextStyle scriptureM;
  final TextStyle scriptureS;
  final TextStyle header;
  final TextStyle label;
  final TextStyle caption;

  @override
  BibleTextTheme copyWith({
    TextStyle? scriptureXxl,
    TextStyle? scriptureXl,
    TextStyle? scriptureL,
    TextStyle? scriptureM,
    TextStyle? scriptureS,
    TextStyle? header,
    TextStyle? label,
    TextStyle? caption,
  }) {
    return BibleTextTheme(
      scriptureXxl: scriptureXxl ?? this.scriptureXxl,
      scriptureXl: scriptureXl ?? this.scriptureXl,
      scriptureL: scriptureL ?? this.scriptureL,
      scriptureM: scriptureM ?? this.scriptureM,
      scriptureS: scriptureS ?? this.scriptureS,
      header: header ?? this.header,
      label: label ?? this.label,
      caption: caption ?? this.caption,
    );
  }

  @override
  BibleTextTheme lerp(ThemeExtension<BibleTextTheme>? other, double t) {
    if (other is! BibleTextTheme) return this;
    return BibleTextTheme(
      scriptureXxl: TextStyle.lerp(scriptureXxl, other.scriptureXxl, t)!,
      scriptureXl: TextStyle.lerp(scriptureXl, other.scriptureXl, t)!,
      scriptureL: TextStyle.lerp(scriptureL, other.scriptureL, t)!,
      scriptureM: TextStyle.lerp(scriptureM, other.scriptureM, t)!,
      scriptureS: TextStyle.lerp(scriptureS, other.scriptureS, t)!,
      header: TextStyle.lerp(header, other.header, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }

  /// Reads this extension from [context], falling back to
  /// [BibleTextTheme.fallback] when the ambient [ThemeData] doesn't declare
  /// one (widgets never require [YouVersionPlatformTheme] to be in use).
  static BibleTextTheme of(BuildContext context) {
    return Theme.of(context).extension<BibleTextTheme>() ?? BibleTextTheme.fallback();
  }
}
