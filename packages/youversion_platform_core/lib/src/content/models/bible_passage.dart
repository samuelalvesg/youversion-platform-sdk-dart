/// Text passage - one or more verses, identified by USFM
/// (e.g.: `MAT.1.1` or `JHN.3.16-JHN.3.17`).
///
/// Contract validated against platform-sdk-kotlin, `bibles/models/BiblePassage.kt`.
class BiblePassage {
  BiblePassage({required this.id, required this.content, required this.reference});

  factory BiblePassage.fromJson(Map<String, dynamic> json) {
    return BiblePassage(
      id: json['id'] as String,
      content: json['content'] as String,
      reference: json['reference'] as String,
    );
  }

  final String id;
  final String content;
  final String reference;
}
