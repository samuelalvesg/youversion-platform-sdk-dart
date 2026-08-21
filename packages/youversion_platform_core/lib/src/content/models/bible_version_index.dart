import 'bible_book.dart';

/// Response from `GET /v1/bibles/{id}/index` - full book → chapter → verse
/// tree of a bible, in a single call. Shallower than one might expect: it
/// reuses the [BibleBook] model (with nested `chapters`/`verses`), with no
/// dedicated "index" types.
///
/// Contract validated against platform-sdk-kotlin, `bibles/models/BibleVersionIndex.kt`.
class BibleVersionIndex {
  BibleVersionIndex({this.textDirection, this.books});

  factory BibleVersionIndex.fromJson(Map<String, dynamic> json) {
    return BibleVersionIndex(
      textDirection: json['text_direction'] as String?,
      books: (json['books'] as List<dynamic>?)
          ?.map((b) => BibleBook.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  final String? textDirection;
  final List<BibleBook>? books;
}
