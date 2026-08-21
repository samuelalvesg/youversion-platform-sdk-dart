/// Verse of the day. `day` is the day of the year (1-366).
///
/// Contract validated against platform-sdk-kotlin, `votd/models/YouVersionVerseOfTheDay.kt`.
class VerseOfTheDay {
  VerseOfTheDay({required this.day, required this.passageId});

  factory VerseOfTheDay.fromJson(Map<String, dynamic> json) {
    return VerseOfTheDay(
      day: json['day'] as int,
      passageId: json['passage_id'] as String,
    );
  }

  final int day;
  final String passageId;
}
