/// CDN renditions accepted by an image URL's `size` query parameter.
enum VerseImageSize { thumb, card, full }

/// A verse-art record (`GET /v1/images/{image_id}` and the `/v1/images`
/// collection). The API never returns bytes: [imageUrl] points at the CDN.
class VerseImage {
  const VerseImage({
    required this.id,
    required this.imageUrl,
    required this.passageId,
    required this.attribution,
    required this.languageTag,
    required this.width,
    required this.height,
    required this.aspectRatio,
  });

  factory VerseImage.fromJson(Map<String, dynamic> json) => VerseImage(
        id: json['id'] as String,
        imageUrl: json['image_url'] as String,
        passageId: json['passage_id'] as String,
        attribution: json['attribution'] as String,
        languageTag: json['language_tag'] as String,
        width: json['width'] as int,
        height: json['height'] as int,
        aspectRatio: (json['aspect_ratio'] as num).toDouble(),
      );

  /// Per-response reference: do not store it or compare it across responses.
  final String id;

  /// Clean CDN URL (no query string); use [sizedUrl] to pick a rendition.
  final String imageUrl;
  final String passageId;

  /// Credit line that must be shown next to the image.
  final String attribution;
  final String languageTag;
  final int width;
  final int height;
  final double aspectRatio;

  /// [imageUrl] with the `size` preset appended; [VerseImageSize.full] is the
  /// CDN default, so it leaves the URL untouched.
  Uri sizedUrl(VerseImageSize size) {
    final uri = Uri.parse(imageUrl);
    if (size == VerseImageSize.full) return uri;
    return uri
        .replace(queryParameters: {...uri.queryParameters, 'size': size.name});
  }
}

/// An image hit from search: only a per-response id and the passage it
/// illustrates. Resolve it with `YouVersionImagesClient.getImage`.
class ImageReference {
  const ImageReference({required this.id, required this.passageId});

  factory ImageReference.fromJson(Map<String, dynamic> json) => ImageReference(
      id: json['id'] as String, passageId: json['passage_id'] as String);

  final String id;
  final String passageId;
}

/// One page of image references (`/v1/search-images`).
class ImageSearchPage {
  const ImageSearchPage({required this.images, this.nextPageToken});

  /// What the API answers with `204 No Content`.
  const ImageSearchPage.empty()
      : images = const [],
        nextPageToken = null;

  factory ImageSearchPage.fromJson(Map<String, dynamic> json) =>
      ImageSearchPage(
        images: (json['images'] as List<dynamic>? ?? const [])
            .map((i) => ImageReference.fromJson(i as Map<String, dynamic>))
            .toList(),
        nextPageToken: json['next_page_token'] as String?,
      );

  final List<ImageReference> images;
  final String? nextPageToken;

  bool get hasNextPage => nextPageToken != null;
}

/// One page of full image records (`/v1/images`).
class VerseImagePage {
  const VerseImagePage(
      {required this.images, this.nextPageToken, this.totalSize});

  /// What the API answers with `204 No Content`.
  const VerseImagePage.empty()
      : images = const [],
        nextPageToken = null,
        totalSize = null;

  factory VerseImagePage.fromJson(Map<String, dynamic> json) => VerseImagePage(
        images: (json['data'] as List<dynamic>? ?? const [])
            .map((i) => VerseImage.fromJson(i as Map<String, dynamic>))
            .toList(),
        nextPageToken: json['next_page_token'] as String?,
        totalSize: json['total_size'] as int?,
      );

  final List<VerseImage> images;
  final String? nextPageToken;

  /// Only populated when the request filtered by `passage_id`.
  final int? totalSize;

  bool get hasNextPage => nextPageToken != null;
}
