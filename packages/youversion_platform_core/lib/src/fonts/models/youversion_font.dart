/// A brand font family served by `GET /v1/fonts/{id}`. Each variant lists the
/// files to register for one weight and style, in preferred order.
class YouVersionFont {
  const YouVersionFont({
    required this.id,
    required this.slug,
    required this.family,
    required this.variants,
  });

  factory YouVersionFont.fromJson(Map<String, dynamic> json) {
    final font = YouVersionFont(
      id: json['id'] as int,
      slug: json['slug'] as String,
      family: json['family'] as String,
      variants: (json['variants'] as List<dynamic>)
          .map((v) => FontVariant.fromJson(v as Map<String, dynamic>))
          .toList(growable: false),
    );
    for (final variant in font.variants) {
      for (final source in variant.sources) {
        final host = Uri.parse(source.url).host;
        if (!allowedFontHosts.contains(host)) {
          throw FormatException('font file host not allowed: $host');
        }
      }
    }
    return font;
  }

  /// Hosts the font files may be downloaded from.
  static const allowedFontHosts = {'api.youversion.com', 'cdn.youversion.com'};

  final int id;
  final String slug;
  final String family;
  final List<FontVariant> variants;
}

class FontVariant {
  const FontVariant({required this.weight, required this.style, required this.sources});

  factory FontVariant.fromJson(Map<String, dynamic> json) {
    final weight = json['weight'] as int;
    final style = json['style'] as String;
    if (!const {400, 500, 700}.contains(weight)) {
      throw FormatException('unsupported font weight: $weight');
    }
    if (style != 'normal' && style != 'italic') {
      throw FormatException('unsupported font style: $style');
    }
    return FontVariant(
      weight: weight,
      style: style,
      sources: (json['sources'] as List<dynamic>)
          .map((s) => FontSource.fromJson(s as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int weight;
  final String style;
  final List<FontSource> sources;
}

class FontSource {
  const FontSource({required this.format, required this.url});

  factory FontSource.fromJson(Map<String, dynamic> json) {
    final format = json['format'] as String;
    if (format != 'woff2' && format != 'ttf') {
      throw FormatException('unsupported font format: $format');
    }
    return FontSource(format: format, url: json['url'] as String);
  }

  final String format;
  final String url;
}
