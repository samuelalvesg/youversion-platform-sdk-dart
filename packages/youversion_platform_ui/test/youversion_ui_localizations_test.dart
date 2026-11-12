import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

void main() {
  testWidgets('falls back to English when the host app registers no delegate', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: YouVersionSignInButton(onPressed: () {})),
      ),
    );

    expect(find.text('Sign in with YouVersion'), findsOneWidget);
  });

  testWidgets('uses the localized string once the delegate is registered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        // The generated list carries Flutter's own Material/Cupertino delegates; `material_ui` and
        // `cupertino_ui` look for their own, so the test registers those too.
        localizationsDelegates: [
          ...YouVersionUiLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: YouVersionUiLocalizations.supportedLocales,
        home: Scaffold(body: YouVersionSignInButton(onPressed: () {})),
      ),
    );

    expect(find.text('Entrar com YouVersion'), findsOneWidget);
  });
}
