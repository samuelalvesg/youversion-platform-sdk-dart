import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

void main() {
  testWidgets('shows HighlightColors.all swatches by default', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: VerseActionSheet())),
    );

    expect(find.byType(GestureDetector), findsWidgets);
    // 5 color circles rendered as separate `Container`s inside `InkWell`s -
    // asserting the exact count (not just >0) catches an accidental
    // duplicate/missing swatch.
    expect(find.byWidgetPredicate(_isColorSwatch), findsNWidgets(5));
  });

  testWidgets('honors a custom colors list instead of HighlightColors.all', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VerseActionSheet(
            colors: HighlightColors.colorblindSafe,
            onColorSelected: (hex) => tapped = hex,
          ),
        ),
      ),
    );

    expect(find.byWidgetPredicate(_isColorSwatch), findsNWidgets(5));

    await tester.tap(find.byWidgetPredicate(_isColorSwatch).first);
    expect(tapped, HighlightColors.colorblindSafe.first);
  });
}

bool _isColorSwatch(Widget w) =>
    w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).shape == BoxShape.circle;
