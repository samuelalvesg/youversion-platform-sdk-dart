import 'bible_book_intro.dart';
import 'bible_chapter.dart';

/// Book within a bible (e.g.: Genesis, Matthew). `id` is the book's USFM
/// code (e.g.: `GEN`, `MAT`).
///
/// Contract validated against platform-sdk-kotlin, `bibles/models/BibleBook.kt`.
class BibleBook {
  BibleBook({
    required this.id,
    this.title,
    this.fullTitle,
    this.abbreviation,
    this.canon,
    this.chapters,
    this.intro,
  });

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      id: json['id'] as String,
      title: json['title'] as String?,
      fullTitle: json['full_title'] as String?,
      abbreviation: json['abbreviation'] as String?,
      canon: json['canon'] as String?,
      chapters:
          (json['chapters'] as List<dynamic>?)?.map((c) => BibleChapter.fromJson(c as Map<String, dynamic>)).toList(),
      intro: json['intro'] == null ? null : BibleBookIntro.fromJson(json['intro'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String? title;
  final String? fullTitle;
  final String? abbreviation;
  final String? canon;

  /// Only populated when the book is read within
  /// `YouVersionContentClient.getIndex` - `listBooks`/`getBook` alone
  /// don't bring the chapters.
  final List<BibleChapter>? chapters;
  final BibleBookIntro? intro;

  bool get isCanonical => canon == 'old_testament' || canon == 'new_testament';
}
