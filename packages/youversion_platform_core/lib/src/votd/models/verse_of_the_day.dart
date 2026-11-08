/// Verse of the day. `day` is the day of the year (1-366).
///
/// Contract validated against platform-sdk-kotlin, `votd/models/YouVersionVerseOfTheDay.kt`.
class VerseOfTheDay {
  VerseOfTheDay({required this.day, required this.passageId, this.imageId});

  factory VerseOfTheDay.fromJson(Map<String, dynamic> json) {
    return VerseOfTheDay(
      day: json['day'] as int,
      passageId: json['passage_id'] as String,
      imageId: json['image_id'] as String?,
    );
  }

  final int day;
  final String passageId;

  /// Per-response image reference, only present when `language_ranges[]` was
  /// sent and that language has art for the day. Never store it.
  final String? imageId;
}
