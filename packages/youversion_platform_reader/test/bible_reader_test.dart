import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

const _content = '<div><div class="p"><span class="yv-v" v="16"></span><span class="yv-vlbl">16</span>'
    'For God so loved the world.</div></div>';

BibleVersionIndex _index() {
  return BibleVersionIndex.fromJson({
    'text_direction': 'ltr',
    'books': [
      {
        'id': 'JHN',
        'title': 'John',
        'chapters': [
          {'id': 'JHN.3', 'passage_id': 'JHN.3'},
        ],
      },
    ],
  });
}

/// In-memory [YouVersionReaderStorage] - no `shared_preferences` plugin
/// bindings needed in a widget test.
class _MemoryStorage implements YouVersionReaderStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async => _values[key] = value;
}

void main() {
  http.Response jsonResponse(Object body) =>
      http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

  testWidgets('tapping a verse opens VerseActionSheet; picking a color highlights that verse only', (tester) async {
    var createdPassageId = '';
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/passages/')) {
        return jsonResponse({'id': 'JHN.3', 'content': _content, 'reference': 'John 3'});
      }
      if (request.method == 'GET' && request.url.path == '/v1/highlights') {
        return http.Response('', 204);
      }
      if (request.method == 'POST' && request.url.path == '/v1/highlights') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        createdPassageId = (body['highlight'] as Map<String, dynamic>)['passage_id'] as String;
        return jsonResponse({
          'data': {'id': 'h1', 'bible_id': 206, 'passage_id': createdPassageId, 'color': 'fffe00'},
        });
      }
      return http.Response('not found', 404);
    });
    final httpClient = YouVersionHttpClient(client: mockClient);

    await tester.pumpWidget(
      MaterialApp(
        home: BibleReader(
          content: YouVersionContentClient(appKey: 'k', httpClient: httpClient),
          bible: Bible.fromJson({'id': 206, 'title': 'WEBUS'}),
          index: _index(),
          initialChapterId: 'JHN.3',
          storage: _MemoryStorage(),
          highlightsClient: YouVersionHighlightsClient(appKey: 'k', httpClient: httpClient),
          userAccessToken: 'token',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('loved'));
    await tester.pumpAndSettle();

    expect(find.byType(VerseActionSheet), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Yellow highlight'));
    await tester.pumpAndSettle();

    expect(createdPassageId, 'JHN.3.16');
  });

  testWidgets('picking a highlight color marks the verse immediately, even signed out (offline-queued)', (
    tester,
  ) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/passages/')) {
        return jsonResponse({'id': 'JHN.3', 'content': _content, 'reference': 'John 3'});
      }
      return http.Response('not found', 404);
    });
    final httpClient = YouVersionHttpClient(client: mockClient);

    await tester.pumpWidget(
      MaterialApp(
        home: BibleReader(
          content: YouVersionContentClient(appKey: 'k', httpClient: httpClient),
          bible: Bible.fromJson({'id': 206, 'title': 'WEBUS'}),
          index: _index(),
          initialChapterId: 'JHN.3',
          storage: _MemoryStorage(),
          highlightsClient: YouVersionHighlightsClient(appKey: 'k', httpClient: httpClient),
          // No userAccessToken - signed out, should still mark optimistically.
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('loved'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Yellow highlight'));
    await tester.pumpAndSettle();

    // The sheet's own local state (not a rebuild from the parent) should
    // already show the swatch as selected.
    final swatch = tester.widget<Semantics>(find.bySemanticsLabel('Yellow highlight'));
    expect(swatch.properties.selected, isTrue);
  });

  testWidgets('reading theme changes the Scaffold background to the theme color', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/passages/')) {
        return jsonResponse({'id': 'JHN.3', 'content': _content, 'reference': 'John 3'});
      }
      return http.Response('not found', 404);
    });
    final httpClient = YouVersionHttpClient(client: mockClient);
    final storage = _MemoryStorage();
    await storage.setString(
      'youversion_reader_font_settings',
      jsonEncode(const ReaderFontSettings(theme: ReaderTheme.trueBlack).toJson()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BibleReader(
          content: YouVersionContentClient(appKey: 'k', httpClient: httpClient),
          bible: Bible.fromJson({'id': 206, 'title': 'WEBUS'}),
          index: _index(),
          initialChapterId: 'JHN.3',
          storage: storage,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, ReaderTheme.trueBlack.background);

    // The ambient MaterialApp here has no explicit theme/darkTheme, so it
    // resolves *light* by default - this reproduces the exact bug found by
    // live testing: reader theme dark + ambient/system theme light. Without
    // `textTheme.apply(...)`, plain Text widgets (not going through
    // BibleTextTheme) stayed dark-on-dark, unreadable against the dark
    // reading canvas.
    final chapterIdText = tester.widget<Text>(find.text('JHN.3'));
    final resolvedColor =
        chapterIdText.style?.color ?? DefaultTextStyle.of(tester.element(find.text('JHN.3'))).style.color;
    expect(resolvedColor, ReaderTheme.trueBlack.foreground);
  });

  testWidgets('reading theme also recolors the AppBar back button - not just text', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/passages/')) {
        return jsonResponse({'id': 'JHN.3', 'content': _content, 'reference': 'John 3'});
      }
      return http.Response('not found', 404);
    });
    final httpClient = YouVersionHttpClient(client: mockClient);
    final storage = _MemoryStorage();
    await storage.setString(
      'youversion_reader_font_settings',
      jsonEncode(const ReaderFontSettings(theme: ReaderTheme.trueBlack).toJson()),
    );

    // BibleReader needs to be *pushed* (not `home`) for Flutter to
    // auto-insert a back button in its AppBar at all - reproduces the bug
    // report exactly: pushed the reader, the back button was there but
    // invisible (same ambient-vs-reader-theme color mismatch as the text
    // bug above, in a separate ThemeData slot - icons don't read
    // `textTheme`).
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BibleReader(
                      content: YouVersionContentClient(appKey: 'k', httpClient: httpClient),
                      bible: Bible.fromJson({'id': 206, 'title': 'WEBUS'}),
                      index: _index(),
                      initialChapterId: 'JHN.3',
                      storage: storage,
                    ),
                  ),
                ),
                child: const Text('Open reader'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open reader'));
    await tester.pumpAndSettle();

    final backButtonContext = tester.element(find.byType(BackButtonIcon));
    expect(IconTheme.of(backButtonContext).color, ReaderTheme.trueBlack.foreground);
  });
}
