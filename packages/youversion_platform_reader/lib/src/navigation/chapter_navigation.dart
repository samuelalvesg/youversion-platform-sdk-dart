import 'package:youversion_platform_core/youversion_platform_core.dart';

/// Pure-Dart chapter navigation over a [BibleVersionIndex] - no widget/state
/// dependency, so it's directly unit-testable. Ports the prev/next-chapter
/// logic from `platform-reader`'s `domain/BibleReaderRepository.kt`
/// (Kotlin): crossing into the previous/next book at chapter boundaries,
/// and treating a book's intro as a pseudo-chapter that comes before
/// chapter 1.
abstract final class ChapterNavigation {
  /// The chapter (or, if [BibleBook.intro] exists and [chapterId] is the
  /// book's first chapter, the intro) immediately before [chapterId].
  /// Returns `null` at the very first chapter of the bible with no intro.
  static String? previous(BibleVersionIndex index, String chapterId) {
    final books = index.books;
    if (books == null || books.isEmpty) return null;

    final bookId = chapterId.split('.').first;
    final bookIndex = books.indexWhere((b) => b.id == bookId);
    if (bookIndex == -1) return null;

    final book = books[bookIndex];
    final chapters = book.chapters ?? const [];
    final chapterIndex = chapters.indexWhere((c) => c.id == chapterId);
    if (chapterIndex == -1) return null;

    if (chapterIndex > 0) return chapters[chapterIndex - 1].id;

    // First chapter of the book: fall back to this book's intro, then to
    // the previous book's last chapter.
    if (book.intro != null) return '$bookId.intro';

    for (var i = bookIndex - 1; i >= 0; i--) {
      final previousBook = books[i];
      final previousChapters = previousBook.chapters ?? const [];
      if (previousChapters.isNotEmpty) return previousChapters.last.id;
      if (previousBook.intro != null) return '${previousBook.id}.intro';
    }
    return null;
  }

  /// The chapter immediately after [chapterId]. Returns `null` at the very
  /// last chapter of the bible.
  static String? next(BibleVersionIndex index, String chapterId) {
    final books = index.books;
    if (books == null || books.isEmpty) return null;

    final bookId = chapterId.split('.').first;
    final bookIndex = books.indexWhere((b) => b.id == bookId);
    if (bookIndex == -1) return null;

    final book = books[bookIndex];
    final chapters = book.chapters ?? const [];
    final chapterIndex = chapters.indexWhere((c) => c.id == chapterId);
    if (chapterIndex == -1) return null;

    if (chapterIndex < chapters.length - 1) return chapters[chapterIndex + 1].id;

    for (var i = bookIndex + 1; i < books.length; i++) {
      final nextBook = books[i];
      if (nextBook.intro != null) return '${nextBook.id}.intro';
      final nextChapters = nextBook.chapters ?? const [];
      if (nextChapters.isNotEmpty) return nextChapters.first.id;
    }
    return null;
  }
}
