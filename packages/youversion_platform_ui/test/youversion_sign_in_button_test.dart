import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

void main() {
  testWidgets('YouVersionSignInButton calls onPressed', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YouVersionSignInButton(onPressed: () => pressed = true),
        ),
      ),
    );

    await tester.tap(find.byType(OutlinedButton));
    expect(pressed, isTrue);
  });

  testWidgets('YouVersionSignInButton disables while loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YouVersionSignInButton(onPressed: () {}, isLoading: true),
        ),
      ),
    );

    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
  });
}
