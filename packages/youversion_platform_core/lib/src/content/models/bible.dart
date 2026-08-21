/// Bible/translation available in the Content API. `id` is YouVersion's
/// numeric "version id" (e.g.: KJV = 1, NIV = 111) - not an abbreviation.
///
/// Contract validated against platform-sdk-kotlin, `bibles/models/BibleVersion.kt`
/// (there the type is called `BibleVersion` - kept as `Bible` here to match
/// the client's `getBible`/`listBibles` method name).
class Bible {
  Bible({
    required this.id,
    this.abbreviation,
    this.title,
    this.languageTag,
    this.organizationId,
    this.promotionalContent,
    this.copyright,
    this.localizedAbbreviation,
    this.localizedTitle,
    this.readerFooter,
    this.readerFooterUrl,
    this.bookCodes,
    this.textDirection,
    this.youVersionDeepLink,
  });

  factory Bible.fromJson(Map<String, dynamic> json) {
    return Bible(
      id: json['id'] as int,
      abbreviation: json['abbreviation'] as String?,
      title: json['title'] as String?,
      languageTag: json['language_tag'] as String?,
      organizationId: json['organization_id'] as String?,
      promotionalContent: json['promotional_content'] as String?,
      copyright: json['copyright'] as String?,
      localizedAbbreviation: json['localized_abbreviation'] as String?,
      localizedTitle: json['localized_title'] as String?,
      readerFooter: json['info'] as String?,
      readerFooterUrl: json['publisher_url'] as String?,
      bookCodes: (json['books'] as List<dynamic>?)?.cast<String>(),
      textDirection: json['text_direction'] as String?,
      youVersionDeepLink: json['youversion_deep_link'] as String?,
    );
  }

  final int id;
  final String? abbreviation;
  final String? title;
  final String? languageTag;
  final String? organizationId;
  final String? promotionalContent;
  final String? copyright;
  final String? localizedAbbreviation;
  final String? localizedTitle;

  /// Short publisher attribution label (JSON field `info`).
  final String? readerFooter;

  /// Publisher URL associated with [readerFooter] (JSON field `publisher_url`).
  final String? readerFooterUrl;

  /// USFM codes of the books contained in this bible (JSON field `books`,
  /// codes only - use `YouVersionContentClient.getIndex` to get the full
  /// `BibleBook` objects).
  final List<String>? bookCodes;

  /// `"ltr"` or `"rtl"` - only populated after `getIndex`
  /// (`/v1/bibles/{id}/index`), not in `listBibles`/`getBible`.
  final String? textDirection;

  final String? youVersionDeepLink;

  bool get isRightToLeft => textDirection == 'rtl';
}
