import '../../http/youversion_exception.dart';
import '../../http/youversion_http_client.dart';
import '../../http/youversion_sdk_headers.dart';
import '../models/bible.dart';
import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import '../models/bible_passage.dart';
import '../models/bible_verse.dart';
import '../models/bible_version_index.dart';
import '../models/collection.dart';

/// Content API client (`/v1/bibles/...`) - Bible text. Authenticates via
/// the static `X-YVP-App-Key` header, no OAuth.
///
/// `versionId` (the parameter named `bibleId` here) is the numeric id of
/// the version on YouVersion (e.g. KJV = 1), not an abbreviation.
///
/// Contract validated against platform-sdk-kotlin, `bibles/api/BiblesEndpoints.kt`.
class YouVersionContentClient {
  YouVersionContentClient({
    required String appKey,
    String? installationId,
    Uri? baseUri,
    YouVersionHttpClient? httpClient,
  })  : _appKey = appKey,
        _installationId = installationId,
        _baseUri = baseUri ?? Uri.parse('https://api.youversion.com'),
        _http = httpClient ?? YouVersionHttpClient();

  final String _appKey;
  final String? _installationId;
  final Uri _baseUri;
  final YouVersionHttpClient _http;

  // In-memory only - dedups concurrent identical requests (two callers
  // asking for the same bible/book/chapter/verse/passage/listing at once
  // share one HTTP request) and caches completed results for this
  // client instance's lifetime, cleared on `close()`. Matches the
  // pattern in platform-sdk-kotlin's `BibleVersionRepository`/
  // `BibleChapterRepository` (`Map<key, Deferred<T>>` + `Mutex`) - Dart's
  // single-threaded event loop makes a plain `Map` race-free here as
  // long as the `Future` is stored before the first `await`, so no
  // Mutex/lock dependency is needed. This is NOT the "offline content
  // cache" this package deliberately doesn't implement (see
  // `docs/DECISIONS.md`'s "storage-agnostic" principle) - nothing here
  // touches disk or survives past this instance's `close()`.
  final Map<String, Object?> _cache = {};
  final Map<String, Future<Object?>> _inFlight = {};

  Future<T> _dedupedCached<T>(String key, Future<T> Function() fetch) {
    if (_cache.containsKey(key)) return Future.value(_cache[key] as T);
    final inFlight = _inFlight[key];
    if (inFlight != null) return inFlight.then((value) => value as T);

    final future = fetch();
    _inFlight[key] = future;
    return future.then((value) {
      _cache[key] = value;
      return value;
    }).whenComplete(() => _inFlight.remove(key));
  }

  Map<String, String> get _headers => youVersionSdkHeaders(appKey: _appKey, installationId: _installationId);

  /// `401` = missing/invalid `X-YVP-App-Key` - confirmed live (an empty or
  /// invalid key returns `401` with an Apigee gateway fault body, distinct
  /// from the app's own `{"message": ...}` `404` shape). Everything else
  /// stays the generic default - no `400`/`406` distinction was observed
  /// live for this API, so none is invented here.
  YouVersionErrorReason _reasonForGet(int status) =>
      status == 401 ? YouVersionErrorReason.missingAuthentication : YouVersionErrorReason.cannotDownload;

  /// Lists Bibles available for the languages in [languageRanges]
  /// (BCP 47, e.g. `['pt', 'en']`). Empty = all languages (`*`).
  ///
  /// [fields] requests a subset of fields (sparse fieldset) - when it has
  /// 1 to 3 items, the server forces `page_size=*` (returns everything on
  /// a single page), the same rule applied by the official SDKs.
  Future<YouVersionCollection<Bible>> listBibles({
    List<String> languageRanges = const [],
    List<String>? fields,
    int? pageSize,
    String? pageToken,
  }) {
    final key = 'listBibles:${languageRanges.join(',')}:${fields?.join(',')}:$pageSize:$pageToken';
    return _dedupedCached(key, () async {
      final uri = _baseUri.replace(
        path: '/v1/bibles',
        queryParameters: {
          'language_ranges[]': languageRanges.isEmpty ? '*' : languageRanges.join(','),
          if (fields != null) 'fields[]': fields,
          if (pageSize != null) 'page_size': '$pageSize',
          if (pageToken != null) 'page_token': pageToken,
        },
      );
      final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
      return YouVersionCollection.fromJson(json, Bible.fromJson);
    });
  }

  /// Fetches a Bible by id (basic metadata, no book list - use
  /// [getIndex] for that).
  Future<Bible> getBible(int bibleId) {
    return _dedupedCached('bible:$bibleId', () async {
      final uri = _baseUri.replace(path: '/v1/bibles/$bibleId');
      final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
      return Bible.fromJson(_unwrap(json));
    });
  }

  /// Full book → chapter → verse tree for a Bible, in a single call
  /// (`GET /v1/bibles/{id}/index`), including `textDirection` (RTL/LTR).
  Future<BibleVersionIndex> getIndex(int bibleId) {
    return _dedupedCached('index:$bibleId', () async {
      final uri = _baseUri.replace(path: '/v1/bibles/$bibleId/index');
      final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
      return BibleVersionIndex.fromJson(_unwrap(json));
    });
  }

  /// Fetches a passage of text by its USFM id (e.g. `MAT.1.1`, `JHN.3.16-JHN.3.17`).
  ///
  /// [format] is `'html'` or `'text'` (the only two the API documents/
  /// supports - confirmed live against `/v1/bibles/{id}/passages/{id}`;
  /// `'json'` is not a real option despite appearing as a raw string in
  /// Kotlin's own URL-building test, which never asserts the server
  /// actually accepts it - it 404s). `'html'` is what
  /// `youversion_platform_ui`'s `BibleTextView` parses (verse numbers,
  /// words-of-Christ, footnotes); `'text'` drops all of that structure.
  Future<BiblePassage> getPassage({
    required int bibleId,
    required String passageId,
    String format = 'html',
    bool includeHeadings = true,
    bool includeNotes = true,
  }) {
    final key = 'passage:$bibleId:$passageId:$format:$includeHeadings:$includeNotes';
    return _dedupedCached(key, () async {
      final uri = _baseUri.replace(
        path: '/v1/bibles/$bibleId/passages/$passageId',
        queryParameters: {
          'format': format,
          'include_headings': '$includeHeadings',
          'include_notes': '$includeNotes',
        },
      );
      final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
      return BiblePassage.fromJson(_unwrap(json));
    });
  }

  /// Lists the books of a Bible.
  Future<List<BibleBook>> listBooks(int bibleId) {
    return _dedupedCached('books:$bibleId', () async {
      final uri = _baseUri.replace(path: '/v1/bibles/$bibleId/books');
      final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
      final items = json['data'] as List<dynamic>? ?? const [];
      return items.map((item) => BibleBook.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  /// Fetches a single book (USFM, e.g. `MAT`).
  Future<BibleBook> getBook({required int bibleId, required String bookUsfm}) {
    return _dedupedCached('book:$bibleId:$bookUsfm', () async {
      final uri = _baseUri.replace(path: '/v1/bibles/$bibleId/books/$bookUsfm');
      final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
      return BibleBook.fromJson(_unwrap(json));
    });
  }

  /// Lists the chapters of a book (USFM, e.g. `MAT`).
  Future<List<BibleChapter>> listChapters({
    required int bibleId,
    required String bookUsfm,
  }) {
    return _dedupedCached('chapters:$bibleId:$bookUsfm', () async {
      final uri = _baseUri.replace(
        path: '/v1/bibles/$bibleId/books/$bookUsfm/chapters',
      );
      final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
      final items = json['data'] as List<dynamic>? ?? const [];
      return items.map((item) => BibleChapter.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  /// Fetches a single chapter (USFM, e.g. `MAT.1`).
  Future<BibleChapter> getChapter({
    required int bibleId,
    required String bookUsfm,
    required String chapterId,
  }) {
    return _dedupedCached('chapter:$bibleId:$bookUsfm:$chapterId', () async {
      final uri = _baseUri.replace(
        path: '/v1/bibles/$bibleId/books/$bookUsfm/chapters/$chapterId',
      );
      final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
      return BibleChapter.fromJson(_unwrap(json));
    });
  }

  /// Lists the verses of a chapter (USFM, e.g. `MAT.1`).
  Future<List<BibleVerse>> listVerses({
    required int bibleId,
    required String bookUsfm,
    required String chapterId,
  }) {
    return _dedupedCached('verses:$bibleId:$bookUsfm:$chapterId', () async {
      final uri = _baseUri.replace(
        path: '/v1/bibles/$bibleId/books/$bookUsfm/chapters/$chapterId/verses',
      );
      final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
      final items = json['data'] as List<dynamic>? ?? const [];
      return items.map((item) => BibleVerse.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  /// Fetches a single verse (USFM, e.g. `MAT.1.1`).
  Future<BibleVerse> getVerse({
    required int bibleId,
    required String bookUsfm,
    required String chapterId,
    required String verseId,
  }) {
    final key = 'verse:$bibleId:$bookUsfm:$chapterId:$verseId';
    return _dedupedCached(key, () async {
      final uri = _baseUri.replace(
        path: '/v1/bibles/$bibleId/books/$bookUsfm/chapters/$chapterId/verses/$verseId',
      );
      final json = await _http.getJson(uri, headers: _headers, reasonForStatus: _reasonForGet);
      return BibleVerse.fromJson(_unwrap(json));
    });
  }

  /// Single-item endpoints are wrapped as `{"data": {...}}`, same as
  /// lists - but some return the object directly at the root depending on
  /// the API version. Accepts both forms.
  Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }

  void close() {
    _http.close();
    _cache.clear();
    _inFlight.clear();
  }
}
