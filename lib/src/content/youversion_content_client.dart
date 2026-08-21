import '../http/youversion_http_client.dart';
import 'models.dart';

/// Cliente da Content API (`/v1/bibles/...`) - texto bíblico. Autenticação
/// via header estático `X-YVP-App-Key`, sem OAuth.
///
/// `versionId` (o parâmetro chamado `bibleId` aqui) é o id numérico da
/// versão na YouVersion (ex.: KJV = 1), não uma sigla - confirmado contra
/// o SDK oficial Kotlin (`BiblesEndpoints.kt`).
class YouVersionContentClient {
  YouVersionContentClient({
    required String appKey,
    Uri? baseUri,
    YouVersionHttpClient? httpClient,
  })  : _appKey = appKey,
        _baseUri = baseUri ?? Uri.parse('https://api.youversion.com'),
        _http = httpClient ?? YouVersionHttpClient();

  final String _appKey;
  final Uri _baseUri;
  final YouVersionHttpClient _http;

  Map<String, String> get _headers => {'X-YVP-App-Key': _appKey};

  /// Lista bíblias disponíveis para os idiomas em [languageRanges]
  /// (BCP 47, ex.: `['pt', 'en']`). Vazio = todos os idiomas (`*`).
  Future<List<Bible>> listBibles({
    List<String> languageRanges = const [],
    int? pageSize,
    String? pageToken,
  }) async {
    final uri = _baseUri.replace(
      path: '/v1/bibles',
      queryParameters: {
        'language_ranges[]':
            languageRanges.isEmpty ? '*' : languageRanges.join(','),
        if (pageSize != null) 'page_size': '$pageSize',
        if (pageToken != null) 'page_token': pageToken,
      },
    );
    final json = await _http.getJson(uri, headers: _headers);
    final items = json['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) => Bible.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Busca uma bíblia por id (metadados básicos, sem lista de livros).
  Future<Bible> getBible(int bibleId) async {
    final uri = _baseUri.replace(path: '/v1/bibles/$bibleId');
    final json = await _http.getJson(uri, headers: _headers);
    return Bible.fromJson(_unwrap(json));
  }

  /// Busca um trecho de texto pelo id USFM (ex.: `MAT.1.1`, `JHN.3.16-JHN.3.17`).
  Future<BiblePassage> getPassage({
    required int bibleId,
    required String passageId,
    String format = 'html',
    bool includeHeadings = true,
    bool includeNotes = true,
  }) async {
    final uri = _baseUri.replace(
      path: '/v1/bibles/$bibleId/passages/$passageId',
      queryParameters: {
        'format': format,
        'include_headings': '$includeHeadings',
        'include_notes': '$includeNotes',
      },
    );
    final json = await _http.getJson(uri, headers: _headers);
    return BiblePassage.fromJson(_unwrap(json));
  }

  /// Lista os livros de uma bíblia.
  Future<List<BibleBook>> listBooks(int bibleId) async {
    final uri = _baseUri.replace(path: '/v1/bibles/$bibleId/books');
    final json = await _http.getJson(uri, headers: _headers);
    final items = json['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) => BibleBook.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Lista os capítulos de um livro (USFM, ex.: `MAT`).
  Future<List<BibleChapter>> listChapters({
    required int bibleId,
    required String bookUsfm,
  }) async {
    final uri = _baseUri.replace(
      path: '/v1/bibles/$bibleId/books/$bookUsfm/chapters',
    );
    final json = await _http.getJson(uri, headers: _headers);
    final items = json['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) => BibleChapter.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Lista os versículos de um capítulo (USFM, ex.: `MAT.1`).
  Future<List<BibleVerse>> listVerses({
    required int bibleId,
    required String bookUsfm,
    required String chapterId,
  }) async {
    final uri = _baseUri.replace(
      path: '/v1/bibles/$bibleId/books/$bookUsfm/chapters/$chapterId/verses',
    );
    final json = await _http.getJson(uri, headers: _headers);
    final items = json['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) => BibleVerse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Endpoints de item único (`getBible`/`getPassage`) vêm envelopados como
  /// `{"data": {...}}`, igual às listas - mas alguns (ex.: passages)
  /// retornam o objeto direto na raiz dependendo da versão da API. Aceita
  /// as duas formas.
  Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }

  void close() => _http.close();
}
