/// Highlight (text markup) of an authenticated user.
///
/// Contract validated against platform-sdk-kotlin, `highlights/models/Highlight.kt`.
class Highlight {
  Highlight({
    this.id,
    required this.bibleId,
    required this.passageId,
    required this.color,
    this.userId,
    this.createTime,
    this.updateTime,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] as String?,
      bibleId: json['bible_id'] as int,
      passageId: json['passage_id'] as String,
      color: json['color'] as String,
      userId: json['user_id'] as String?,
      createTime: json['create_time'] as String?,
      updateTime: json['update_time'] as String?,
    );
  }

  // Nullable - confirmed against Kotlin's own model (`id: String? = null`)
  // and live: a real `listHighlights`/`createHighlight` response can omit
  // it. Previously required, which crashed `Highlight.fromJson` with an
  // uncaught type-cast error whenever it was missing - the exact root
  // cause of an "infinite loading" bug report (`BibleReader._loadChapter`
  // has no error handling around `listHighlights`, so the exception left
  // `isLoading` stuck `true` forever - see `docs/DECISIONS.md`).
  final String? id;
  final int bibleId;
  final String passageId;

  /// 6-character hex, lowercase, without `#` (e.g. `fffe00`). See
  /// [HighlightColors] for the official palette.
  final String color;
  final String? userId;
  final String? createTime;
  final String? updateTime;
}

/// Fixed highlight color palette - **not an API resource**, it's a
/// client-side constant identical across all official SDKs (confirmed
/// against platform-sdk-kotlin, `platform-reader/.../sheets/HighlightColor.kt`).
/// A supposedly remote `HighlightColor` endpoint does not exist.
abstract final class HighlightColors {
  static const String yellow = 'fffe00';
  static const String green = '5dff79';
  static const String cyan = '00d6ff';
  static const String orange = 'ffc66f';
  static const String pink = 'ff95ef';

  static const List<String> all = [yellow, green, cyan, orange, pink];
}
