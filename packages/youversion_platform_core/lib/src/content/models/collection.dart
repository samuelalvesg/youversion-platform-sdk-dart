/// Paginated response envelope used by all YouVersion Platform list
/// endpoints (`{"data": [...], "next_page_token": ..., "total_size": ...}`).
///
/// Contract validated against platform-sdk-kotlin, `api/ApiResponse.kt`
/// (`PaginatedResponse<T>`).
class YouVersionCollection<T> {
  YouVersionCollection({
    required this.data,
    this.nextPageToken,
    this.totalSize,
  });

  factory YouVersionCollection.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final items = json['data'] as List<dynamic>? ?? const [];
    return YouVersionCollection(
      data: items.map((item) => fromJsonT(item as Map<String, dynamic>)).toList(),
      nextPageToken: json['next_page_token'] as String?,
      totalSize: json['total_size'] as int?,
    );
  }

  final List<T> data;
  final String? nextPageToken;
  final int? totalSize;

  bool get hasNextPage => nextPageToken != null;
}
