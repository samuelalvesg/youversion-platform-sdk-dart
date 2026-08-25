import 'package:flutter/widgets.dart';

import 'youversion_ui_localizations.dart';
import 'youversion_ui_localizations_en.dart';

/// Zero-config accessor for [YouVersionUiLocalizations].
///
/// Falls back to the bundled English strings when the host app hasn't
/// registered [YouVersionUiLocalizations.delegate] - every widget in this
/// package works without requiring host configuration (same principle as
/// `BibleTextTheme.of`/`ReaderColorScheme.of`). Registering the delegate in
/// the host `MaterialApp` is opt-in, for apps that want localized strings.
YouVersionUiLocalizations youVersionUiStringsOf(BuildContext context) {
  return Localizations.of<YouVersionUiLocalizations>(context, YouVersionUiLocalizations) ??
      YouVersionUiLocalizationsEn();
}
