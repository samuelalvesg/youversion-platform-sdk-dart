import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

void main() {
  const content = '<div><div class="p"><span class="yv-v" v="16"></span><span class="yv-vlbl">16</span>'
      '<span class="wj">For God so loved the world</span><span class="yv-n f"><span class="ft">A note.</span></span>.'
      '</div></div>';

  TextSpan rootSpan(WidgetTester tester) {
    final richText = tester.widgetList<RichText>(find.byType(RichText)).first;
    return richText.text as TextSpan;
  }

  List<TextSpan> flattenSpans(TextSpan root) {
    final result = <TextSpan>[];
    void visit(InlineSpan span) {
      if (span is TextSpan) {
        result.add(span);
        span.children?.forEach(visit);
      }
    }

    visit(root);
    return result;
  }

  testWidgets('tapping a verse calls onVerseTap with the full USFM id', (tester) async {
    String? tappedVerseId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BibleTextView(
            content: content,
            chapterId: 'JHN.3',
            onVerseTap: (id) => tappedVerseId = id,
          ),
        ),
      ),
    );

    final span = flattenSpans(rootSpan(tester)).firstWhere((s) => s.text?.contains('loved') == true);
    final recognizer = span.recognizer as TapGestureRecognizer;
    // Not `.onTap!()` directly - confirmed live, `RenderParagraph`'s own
    // semantics-tree assembly only supports Flutter's own recognizer
    // types on a `TextSpan`, so verse taps are wired via a real
    // `TapGestureRecognizer`'s `onTapDown`/`onTapUp` (to also distinguish
    // a long-press) rather than a bare `.onTap` callback - simulate the
    // same down/up sequence a real tap does.
    recognizer.onTapDown!(TapDownDetails());
    recognizer.onTapUp!(TapUpDetails(kind: PointerDeviceKind.touch));

    expect(tappedVerseId, 'JHN.3.16');
  });

  testWidgets('long-pressing a verse calls onVerseLongPress, not onVerseTap', (tester) async {
    String? tappedVerseId;
    String? longPressedVerseId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BibleTextView(
            content: content,
            chapterId: 'JHN.3',
            onVerseTap: (id) => tappedVerseId = id,
            onVerseLongPress: (id) => longPressedVerseId = id,
          ),
        ),
      ),
    );

    final span = flattenSpans(rootSpan(tester)).firstWhere((s) => s.text?.contains('loved') == true);
    final recognizer = span.recognizer as TapGestureRecognizer;
    recognizer.onTapDown!(TapDownDetails());
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
    recognizer.onTapUp!(TapUpDetails(kind: PointerDeviceKind.touch));

    expect(longPressedVerseId, 'JHN.3.16');
    expect(tappedVerseId, isNull);
  });

  testWidgets('right-clicking a verse calls onVerseLongPress, same as long-press', (tester) async {
    String? tappedVerseId;
    String? longPressedVerseId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BibleTextView(
            content: content,
            chapterId: 'JHN.3',
            onVerseTap: (id) => tappedVerseId = id,
            onVerseLongPress: (id) => longPressedVerseId = id,
          ),
        ),
      ),
    );

    final span = flattenSpans(rootSpan(tester)).firstWhere((s) => s.text?.contains('loved') == true);
    final recognizer = span.recognizer as TapGestureRecognizer;
    // Right mouse button - no long-press timing involved, fires
    // immediately via the same recognizer's `onSecondaryTapUp`.
    recognizer.onSecondaryTapUp!(TapUpDetails(kind: PointerDeviceKind.mouse));

    expect(longPressedVerseId, 'JHN.3.16');
    expect(tappedVerseId, isNull);
  });

  testWidgets('tapping a footnote marker calls onFootnoteTap, not onVerseTap', (tester) async {
    String? tappedFootnote;
    var verseTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BibleTextView(
            content: content,
            chapterId: 'JHN.3',
            onVerseTap: (_) => verseTapped = true,
            onFootnoteTap: (text) => tappedFootnote = text,
          ),
        ),
      ),
    );

    final marker = flattenSpans(rootSpan(tester)).firstWhere((s) => s.text == '*');
    (marker.recognizer as TapGestureRecognizer).onTap!();

    expect(tappedFootnote, 'A note.');
    expect(verseTapped, isFalse);
  });

  testWidgets('a footnote marker is inert when onFootnoteTap is null (backwards compatible default)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BibleTextView(content: content, chapterId: 'JHN.3')),
      ),
    );

    final marker = flattenSpans(rootSpan(tester)).firstWhere((s) => s.text == '*');
    expect(marker.recognizer, isNull);
  });

  testWidgets('selected verse gets a dashed underline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BibleTextView(content: content, chapterId: 'JHN.3', selectedVerseIds: {'JHN.3.16'}),
        ),
      ),
    );

    final span = flattenSpans(rootSpan(tester)).firstWhere((s) => s.text?.contains('loved') == true);
    expect(span.style?.decorationStyle, TextDecorationStyle.dashed);
  });

  testWidgets('a verse with a saved highlight gets a colored background', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BibleTextView(
            content: content,
            chapterId: 'JHN.3',
            highlightsByVerseId: {'JHN.3.16': HighlightColors.yellow},
          ),
        ),
      ),
    );

    final span = flattenSpans(rootSpan(tester)).firstWhere((s) => s.text?.contains('loved') == true);
    expect(span.style?.background, isNotNull);
  });

  testWidgets('words-of-Christ text uses ReaderColorScheme.wordsOfChrist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BibleTextView(content: content, chapterId: 'JHN.3'),
        ),
      ),
    );

    final scheme = ReaderColorScheme.light(const ColorScheme.light());
    final span = flattenSpans(rootSpan(tester)).firstWhere((s) => s.text?.contains('loved') == true);
    expect(span.style?.color, scheme.wordsOfChrist);
  });

  testWidgets('a footnote marker renders without leaking its body text into the visible content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BibleTextView(content: content, chapterId: 'JHN.3'),
        ),
      ),
    );

    final allText = flattenSpans(rootSpan(tester)).map((s) => s.text ?? '').join();
    expect(allText, isNot(contains('A note.')));
    expect(allText, contains('*'));
  });

  testWidgets('a chapterId-less BibleTextView (e.g. BibleCard) never fires onVerseTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BibleTextView(content: content, onVerseTap: (_) => tapped = true),
        ),
      ),
    );

    final span = flattenSpans(rootSpan(tester)).firstWhere((s) => s.text?.contains('loved') == true);
    expect(span.recognizer, isNull);
    expect(tapped, isFalse);
  });
}
