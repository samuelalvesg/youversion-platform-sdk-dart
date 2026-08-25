import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';

void main() {
  testWidgets('tapping a font-size chip updates its own selected state immediately, not just onChanged', (
    tester,
  ) async {
    ReaderFontSettings? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FontSettingsSheet(
            settings: const ReaderFontSettings(fontSize: 15),
            onChanged: (settings) => changed = settings,
          ),
        ),
      ),
    );

    // Sanity: 15 starts selected, 21 doesn't.
    ChoiceChip chipFor(String label) => tester.widget<ChoiceChip>(
          find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip)),
        );
    expect(chipFor('15').selected, isTrue);
    expect(chipFor('21').selected, isFalse);

    await tester.tap(find.text('21'));
    await tester.pump();

    // The sheet is a StatefulWidget with its own local copy of settings -
    // without that, this would still show 15 as selected since nothing
    // external triggers a rebuild of an already-open modal sheet.
    expect(chipFor('21').selected, isTrue);
    expect(chipFor('15').selected, isFalse);
    expect(changed?.fontSize, 21);
  });
}
