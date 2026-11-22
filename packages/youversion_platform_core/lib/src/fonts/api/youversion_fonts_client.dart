import '../../http/youversion_exception.dart';
import '../../http/youversion_http_client.dart';
import '../../http/youversion_sdk_headers.dart';
import '../models/youversion_font.dart';

/// Fonts API (`/v1/fonts/{id}`), App Key auth only, no sign-in.
class YouVersionFontsClient {
  YouVersionFontsClient({
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

  Map<String, String> get _headers =>
      youVersionSdkHeaders(appKey: _appKey, installationId: _installationId);

  YouVersionErrorReason _reason(int status) => switch (status) {
        401 => YouVersionErrorReason.missingAuthentication,
        404 => YouVersionErrorReason.notPermitted,
        _ => YouVersionErrorReason.cannotDownload,
      };

  /// Font family [id] (for example `1`, the brand serif). Unknown ids answer `404`.
  Future<YouVersionFont> getFont(int id) async {
    final uri = _baseUri.replace(pathSegments: ['v1', 'fonts', '$id']);
    final json =
        await _http.getJson(uri, headers: _headers, reasonForStatus: _reason);
    return YouVersionFont.fromJson(json);
  }
}
