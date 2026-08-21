import 'bible_verse.dart';

/// Chapter within a book. `id` is the chapter's USFM (e.g.: `MAT.1`).
///
/// Contract validated against platform-sdk-kotlin, `bibles/models/BibleChapter.kt`.
class BibleChapter {
  BibleChapter({required this.id, this.passageId, this.title, this.verses});

  factory BibleChapter.fromJson(Map<String, dynamic> json) {
    return BibleChapter(
      id: json['id'] as String,
      passageId: json['passage_id'] as String?,
      title: json['title'] as String?,
      verses: (json['verses'] as List<dynamic>?)
          ?.map((v) => BibleVerse.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String? passageId;
  final String? title;

  /// Only populated when the chapter is read within
  /// `YouVersionContentClient.getIndex` - `listChapters`/`getChapter`
  /// alone don't bring the verses.
  final List<BibleVerse>? verses;
}
