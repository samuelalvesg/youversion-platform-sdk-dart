/// Verse within a chapter. `id` is the verse's USFM (e.g.: `MAT.1.1`).
///
/// Contract validated against platform-sdk-kotlin/swift/react: none of the 3
/// official SDKs has a rendered text field here (`id`, `passage_id`,
/// `title` only) - the text comes from
/// `YouVersionContentClient.getPassage(bibleId: ..., passageId: id)`. The
/// [content] field existed in v0.1.0 of this package due to a wrong
/// assumption (not confirmed against any official SDK); kept as optional,
/// null in practice, only for compatibility - don't rely on it.
class BibleVerse {
  BibleVerse({required this.id, this.passageId, this.title, this.content});

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      id: json['id'] as String,
      passageId: json['passage_id'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
    );
  }

  final String id;
  final String? passageId;
  final String? title;

  @Deprecated(
    'No official SDK returns this field in the verse list. Use '
    'YouVersionContentClient.getPassage(bibleId: ..., passageId: id) to '
    'get the text.',
  )
  final String? content;
}
