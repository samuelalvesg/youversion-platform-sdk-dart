import '../../images/models/verse_image.dart';

/// What the searcher is looking for; a wrong hint can skew ranking, so
/// [unknown] (the API default) is the safe choice when unsure.
enum SearchUserIntent {
  unknown,
  text,
  topical,
  reference;

  /// Parses the `user_intent` response field; `null` stays `null` and an
  /// unrecognised value falls back to [unknown] instead of failing the call.
  static SearchUserIntent? fromWire(String? value) {
    if (value == null) return null;
    return SearchUserIntent.values
        .firstWhere((intent) => intent.name == value, orElse: () => unknown);
  }
}

/// Result kinds `search-unified` can return (`fields[]`).
enum SearchField { verses, topics, images }

/// A verse hit. The API returns the USFM reference only (e.g. `JHN.3.16`),
/// never text: resolve it through the passages API.
class SearchVerse {
  const SearchVerse({required this.reference});

  factory SearchVerse.fromJson(Map<String, dynamic> json) =>
      SearchVerse(reference: json['reference'] as String);

  final String reference;
}

class SearchTopic {
  const SearchTopic({required this.text, this.id, this.subtopics = const []});

  factory SearchTopic.fromJson(Map<String, dynamic> json) => SearchTopic(
        id: json['id'] as int?,
        text: json['text'] as String,
        subtopics:
            (json['subtopics'] as List<dynamic>? ?? const []).cast<String>(),
      );

  /// Nullable in the API.
  final int? id;
  final String text;
  final List<String> subtopics;
}

/// A suggested or trending search string.
class SearchQuerySuggestion {
  const SearchQuerySuggestion({required this.text, this.source});

  factory SearchQuerySuggestion.fromJson(Map<String, dynamic> json) =>
      SearchQuerySuggestion(
          text: json['text'] as String, source: json['source'] as String?);

  final String text;

  /// e.g. `community` or `trending`.
  final String? source;
}

/// "Did you mean" data every verse/topic response carries.
class SearchQueryInfo {
  const SearchQueryInfo(
      {this.userIntent, this.didYouMean = const [], this.searchInsteadFor});

  factory SearchQueryInfo.fromJson(Map<String, dynamic> json) =>
      SearchQueryInfo(
        userIntent: SearchUserIntent.fromWire(json['user_intent'] as String?),
        didYouMean:
            (json['did_you_mean'] as List<dynamic>? ?? const []).cast<String>(),
        searchInsteadFor: json['search_instead_for'] as String?,
      );

  /// Not returned by `search-topics`.
  final SearchUserIntent? userIntent;
  final List<String> didYouMean;

  /// The corrected query the results were returned for, when the service
  /// auto-corrected a likely typo.
  final String? searchInsteadFor;
}

/// `GET /v1/search-unified`.
class UnifiedSearchResult {
  const UnifiedSearchResult(
      {required this.verses,
      required this.topics,
      required this.info,
      this.images = const []});

  factory UnifiedSearchResult.fromJson(Map<String, dynamic> json) =>
      UnifiedSearchResult(
        verses: (json['verses'] as List<dynamic>? ?? const [])
            .map((v) => SearchVerse.fromJson(v as Map<String, dynamic>))
            .toList(),
        topics: (json['topics'] as List<dynamic>? ?? const [])
            .map((t) => SearchTopic.fromJson(t as Map<String, dynamic>))
            .toList(),
        images: (json['images'] as List<dynamic>? ?? const [])
            .map((i) => ImageReference.fromJson(i as Map<String, dynamic>))
            .toList(),
        info: SearchQueryInfo.fromJson(json),
      );

  final List<SearchVerse> verses;
  final List<SearchTopic> topics;

  /// Verse art hits (id and passage only); resolve with the Images client.
  final List<ImageReference> images;
  final SearchQueryInfo info;
}

/// One page of `GET /v1/search-verses`.
class VerseSearchPage {
  const VerseSearchPage(
      {required this.verses, required this.info, this.nextPageToken});

  factory VerseSearchPage.fromJson(Map<String, dynamic> json) =>
      VerseSearchPage(
        verses: (json['verses'] as List<dynamic>? ?? const [])
            .map((v) => SearchVerse.fromJson(v as Map<String, dynamic>))
            .toList(),
        info: SearchQueryInfo.fromJson(json),
        nextPageToken: json['next_page_token'] as String?,
      );

  final List<SearchVerse> verses;
  final SearchQueryInfo info;
  final String? nextPageToken;

  bool get hasNextPage => nextPageToken != null;
}

/// `GET /v1/search-topics`.
class TopicSearchResult {
  const TopicSearchResult(
      {required this.topics, required this.info, required this.totalSize});

  factory TopicSearchResult.fromJson(Map<String, dynamic> json) {
    final topics = (json['topics'] as List<dynamic>? ?? const [])
        .map((t) => SearchTopic.fromJson(t as Map<String, dynamic>))
        .toList();
    return TopicSearchResult(
      topics: topics,
      info: SearchQueryInfo.fromJson(json),
      totalSize: json['total_size'] as int? ?? topics.length,
    );
  }

  final List<SearchTopic> topics;
  final SearchQueryInfo info;
  final int totalSize;
}
