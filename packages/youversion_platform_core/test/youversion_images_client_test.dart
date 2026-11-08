import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

YouVersionImagesClient _client(
    http.Response Function(http.Request request) respond) {
  return YouVersionImagesClient(
    appKey: 'my-app-key',
    httpClient: YouVersionHttpClient(
        client: MockClient((request) async => respond(request))),
  );
}

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

Map<String, Object> _image([String id = 'img1']) => {
      'id': id,
      'image_url': 'https://cdn.example.com/a/$id.jpg',
      'passage_id': 'JHN.3.16',
      'attribution': 'Photo by Someone',
      'language_tag': 'en',
      'width': 1080,
      'height': 1350,
      'aspect_ratio': 0.8,
    };

void main() {
  group('getImage', () {
    test('decodes the record and sends the app key', () async {
      late http.Request seen;
      final image = await _client((r) {
        seen = r;
        return _json(_image());
      }).getImage('img1');

      expect(seen.url.path, '/v1/images/img1');
      expect(seen.headers['X-YVP-App-Key'], 'my-app-key');
      expect(image.passageId, 'JHN.3.16');
      expect(image.aspectRatio, 0.8);
      expect(image.attribution, 'Photo by Someone');
    });

    test('sizedUrl adds the size preset and leaves full untouched', () async {
      final image = VerseImage.fromJson(_image());
      expect(image.sizedUrl(VerseImageSize.card).toString(),
          'https://cdn.example.com/a/img1.jpg?size=card');
      expect(image.sizedUrl(VerseImageSize.thumb).queryParameters['size'],
          'thumb');
      expect(image.sizedUrl(VerseImageSize.full).toString(), image.imageUrl);
    });

    test('maps 404 to notPermitted', () async {
      await expectLater(
        _client((_) => http.Response('', 404)).getImage('nope'),
        throwsA(isA<YouVersionException>().having(
            (e) => e.reason, 'reason', YouVersionErrorReason.notPermitted)),
      );
    });
  });

  group('listImages', () {
    test('sends filters, repeats language_ranges[] and reads pagination',
        () async {
      late Uri seen;
      final page = await _client((r) {
        seen = r.url;
        return _json({
          'data': [_image('a'), _image('b')],
          'total_size': 7,
          'next_page_token': 'tok',
        });
      }).listImages(
          passageId: 'JHN.3.16',
          languageRanges: ['en', 'pt'],
          pageSize: 2,
          pageToken: 'prev');

      expect(seen.path, '/v1/images');
      expect(seen.queryParametersAll['language_ranges[]'], ['en', 'pt']);
      expect(seen.queryParameters['passage_id'], 'JHN.3.16');
      expect(seen.queryParameters['page_size'], '2');
      expect(seen.queryParameters['page_token'], 'prev');
      expect(page.images.map((i) => i.id), ['a', 'b']);
      expect(page.totalSize, 7);
      expect(page.hasNextPage, isTrue);
    });

    test('treats an empty 204 body as an empty page', () async {
      final page = await _client((_) => http.Response('', 204))
          .listImages(passageId: 'JHN.3.16');
      expect(page.images, isEmpty);
      expect(page.hasNextPage, isFalse);
    });

    test('rejects an out-of-range page size', () {
      expect(() => _client((_) => _json({})).listImages(pageSize: 100),
          throwsArgumentError);
    });
  });

  group('searchImages', () {
    test('sends query and bible_id and decodes references', () async {
      late Uri seen;
      final page = await _client((r) {
        seen = r.url;
        return _json({
          'images': [
            {'id': 'x', 'passage_id': 'PSA.23.1'},
          ],
          'next_page_token': 'n',
        });
      }).searchImages(query: 'shepherd', bibleId: 3034, pageSize: 5);

      expect(seen.path, '/v1/search-images');
      expect(seen.queryParameters['query'], 'shepherd');
      expect(seen.queryParameters['bible_id'], '3034');
      expect(page.images.single.passageId, 'PSA.23.1');
      expect(page.hasNextPage, isTrue);
    });

    test('treats 204 as an empty page', () async {
      final page = await _client((_) => http.Response('', 204))
          .searchImages(query: 'zzz', bibleId: 1);
      expect(page.images, isEmpty);
    });

    test('validates the query length', () {
      final client = _client((_) => _json({}));
      expect(() => client.searchImages(query: '', bibleId: 1),
          throwsArgumentError);
      expect(() => client.searchImages(query: 'a' * 101, bibleId: 1),
          throwsArgumentError);
    });
  });

  test('unified search decodes image references', () {
    final result = UnifiedSearchResult.fromJson({
      'verses': [],
      'topics': [],
      'images': [
        {'id': 'i1', 'passage_id': 'JHN.3.16'},
      ],
    });
    expect(result.images.single.id, 'i1');
    expect(UnifiedSearchResult.fromJson({'verses': [], 'topics': []}).images,
        isEmpty);
  });
}
