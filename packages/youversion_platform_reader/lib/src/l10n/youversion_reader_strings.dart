import 'package:flutter/widgets.dart';

import 'youversion_reader_localizations.dart';
import 'youversion_reader_localizations_en.dart';

/// Zero-config accessor for [YouVersionReaderLocalizations].
///
/// Falls back to the bundled English strings when the host app hasn't
/// registered [YouVersionReaderLocalizations.delegate] - mirrors
/// `youversion_platform_ui`'s `youVersionUiStringsOf`, and the same
/// no-required-config principle as `BibleTextTheme.of`/`ReaderColorScheme.of`.
YouVersionReaderLocalizations youVersionReaderStringsOf(BuildContext context) {
  return Localizations.of<YouVersionReaderLocalizations>(context, YouVersionReaderLocalizations) ??
      YouVersionReaderLocalizationsEn();
}
