/// Introduction of a book (`BibleBook.intro`). The text itself is fetched
/// via `YouVersionContentClient.getPassage(bibleId: ..., passageId: id)`.
///
/// Contract validated against platform-sdk-kotlin, `bibles/models/BibleBookIntro.kt`.
class BibleBookIntro {
  BibleBookIntro({required this.id, this.passageId, this.title});

  factory BibleBookIntro.fromJson(Map<String, dynamic> json) {
    return BibleBookIntro(
      id: json['id'] as String,
      passageId: json['passage_id'] as String?,
      title: json['title'] as String?,
    );
  }

  final String id;
  final String? passageId;
  final String? title;
}
