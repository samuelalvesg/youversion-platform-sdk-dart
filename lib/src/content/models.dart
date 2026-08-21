/// Bíblia/tradução disponível na Content API. `id` é o "version id"
/// numérico da YouVersion (ex.: KJV = 1, NIV = 111) - não uma sigla.
class Bible {
  Bible({
    required this.id,
    this.abbreviation,
    this.title,
    this.languageTag,
    this.organizationId,
  });

  factory Bible.fromJson(Map<String, dynamic> json) {
    return Bible(
      id: json['id'] as int,
      abbreviation: json['abbreviation'] as String?,
      title: json['title'] as String?,
      languageTag: json['language_tag'] as String?,
      organizationId: json['organization_id'] as String?,
    );
  }

  final int id;
  final String? abbreviation;
  final String? title;
  final String? languageTag;
  final String? organizationId;
}

/// Livro dentro de uma [Bible] (ex.: Gênesis, Mateus). `id` é o código
/// USFM do livro (ex.: `GEN`, `MAT`).
class BibleBook {
  BibleBook({required this.id, this.title, this.fullTitle, this.canon});

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      id: json['id'] as String,
      title: json['title'] as String?,
      fullTitle: json['full_title'] as String?,
      canon: json['canon'] as String?,
    );
  }

  final String id;
  final String? title;
  final String? fullTitle;
  final String? canon;
}

/// Capítulo dentro de um [BibleBook]. `id` é o USFM do capítulo (ex.: `MAT.1`).
class BibleChapter {
  BibleChapter({required this.id, this.title});

  factory BibleChapter.fromJson(Map<String, dynamic> json) {
    return BibleChapter(
      id: json['id'] as String,
      title: json['title'] as String?,
    );
  }

  final String id;
  final String? title;
}

/// Versículo dentro de um [BibleChapter]. `id` é o USFM do versículo
/// (ex.: `MAT.1.1`).
class BibleVerse {
  BibleVerse({required this.id, this.content});

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      id: json['id'] as String,
      content: json['content'] as String?,
    );
  }

  final String id;
  final String? content;
}

/// Trecho de texto (passage) - um ou mais versículos, identificado por USFM
/// (ex.: `MAT.1.1` ou `JHN.3.16-JHN.3.17`).
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
