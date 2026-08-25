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
    final introId = _introId(book);
    if (introId != null && chapterId == introId) {
      // Already at this book's intro - the previous entry point is the
      // previous book (its last chapter, or its own intro).
      return _previousBookEntryPoint(books, bookIndex);
    }

    final chapters = book.chapters ?? const [];
    final chapterIndex = chapters.indexWhere((c) => _chapterId(c) == chapterId);
    if (chapterIndex == -1) return null;

    if (chapterIndex > 0) return _chapterId(chapters[chapterIndex - 1]);

    // First chapter of the book: fall back to this book's intro, then to
    // the previous book's last chapter.
    if (introId != null) return introId;
    return _previousBookEntryPoint(books, bookIndex);
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
    final introId = _introId(book);
    if (introId != null && chapterId == introId) {
      // Already at this book's intro - the next entry point is this
      // book's first chapter.
      if (chapters.isNotEmpty) return _chapterId(chapters.first);
      return _nextBookEntryPoint(books, bookIndex);
    }

    final chapterIndex = chapters.indexWhere((c) => _chapterId(c) == chapterId);
    if (chapterIndex == -1) return null;

    if (chapterIndex < chapters.length - 1) return _chapterId(chapters[chapterIndex + 1]);

    return _nextBookEntryPoint(books, bookIndex);
  }

  static String? _previousBookEntryPoint(List<BibleBook> books, int bookIndex) {
    for (var i = bookIndex - 1; i >= 0; i--) {
      final previousBook = books[i];
      final previousChapters = previousBook.chapters ?? const [];
      if (previousChapters.isNotEmpty) return _chapterId(previousChapters.last);
      final introId = _introId(previousBook);
      if (introId != null) return introId;
    }
    return null;
  }

  static String? _nextBookEntryPoint(List<BibleBook> books, int bookIndex) {
    for (var i = bookIndex + 1; i < books.length; i++) {
      final nextBook = books[i];
      final introId = _introId(nextBook);
      if (introId != null) return introId;
      final nextChapters = nextBook.chapters ?? const [];
      if (nextChapters.isNotEmpty) return _chapterId(nextChapters.first);
    }
    return null;
  }

  /// The real passage id for [book]'s intro (e.g. `"GEN.INTRO"`), as
  /// returned by the API - **not** a guessed/synthesized string. Confirmed
  /// live against `GET /v1/bibles/{id}/index` + `GET .../passages/{id}`:
  /// the intro's `passage_id` is uppercase `INTRO`, no relation to the
  /// lowercase `.intro` this code used to hardcode (which 404s).
  static String? _introId(BibleBook book) {
    final intro = book.intro;
    if (intro == null) return null;
    return intro.passageId ?? intro.id;
  }

  /// The real full USFM id for [chapter] (e.g. `"JHN.3"`) - **not**
  /// [BibleChapter.id], which is confirmed live to be just the bare local
  /// chapter number (e.g. `"3"`), never a full reference. Every
  /// `chapterId` this class deals in is a full passage id, matching what
  /// `YouVersionContentClient.getPassage` expects - comparing/returning
  /// `chapter.id` directly used to make `chapterIndex` always resolve to
  /// `-1` against a real API response, silently breaking prev/next
  /// navigation entirely.
  static String _chapterId(BibleChapter chapter) => chapter.passageId ?? chapter.id;
}
