/// Language supported by the YouVersion Platform.
///
/// Contract validated against platform-sdk-kotlin, `languages/models/Language.kt`
/// (field `default_bible_version_id`, confirmed - not `default_bible_id`).
class Language {
  Language({
    required this.id,
    this.language,
    this.script,
    this.scriptName,
    this.aliases,
    this.displayNames,
    this.scripts,
    this.variants,
    this.countries,
    this.textDirection = 'ltr',
    this.defaultBibleVersionId,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] as String,
      language: json['language'] as String?,
      script: json['script'] as String?,
      scriptName: json['script_name'] as String?,
      aliases: (json['aliases'] as List<dynamic>?)?.cast<String>(),
      displayNames: (json['display_names'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)),
      scripts: (json['scripts'] as List<dynamic>?)?.cast<String>(),
      variants: (json['variants'] as List<dynamic>?)?.cast<String>(),
      countries: (json['countries'] as List<dynamic>?)?.cast<String>(),
      textDirection: json['text_direction'] as String? ?? 'ltr',
      defaultBibleVersionId: json['default_bible_version_id'] as int?,
    );
  }

  final String id;
  final String? language;
  final String? script;
  final String? scriptName;
  final List<String>? aliases;
  final Map<String, String>? displayNames;
  final List<String>? scripts;
  final List<String>? variants;
  final List<String>? countries;
  final String textDirection;
  final int? defaultBibleVersionId;

  bool get isRightToLeft => textDirection == 'rtl';
}
