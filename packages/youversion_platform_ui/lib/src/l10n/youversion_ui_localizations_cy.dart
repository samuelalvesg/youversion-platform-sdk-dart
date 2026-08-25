// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Welsh (`cy`).
class YouVersionUiLocalizationsCy extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsCy([String locale = 'cy']) : super(locale);

  @override
  String get verseOfTheDayLabel => 'Adnod y Dydd';

  @override
  String get searchLanguagesHint => 'Chwilio ieithoedd';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => 'Cau';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => 'Clirio amlygu';

  @override
  String get copyButton => 'Copïo';

  @override
  String get shareButton => 'Rhannu';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage =>
      'Nid yw rhai o\'ch amlygiadau wedi\'u cadw eto, a byddan nhw\'n cael eu colli os byddi di\'n allgofnodi. A wyt am allgofnodi beth bynnag?';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => 'Canslo';

  @override
  String get signOutButton => 'Allgofnodi';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return 'Mewngofnodi gyda $brandName';
  }

  @override
  String get highlightColorYellow => 'Yellow highlight';

  @override
  String get highlightColorGreen => 'Green highlight';

  @override
  String get highlightColorCyan => 'Cyan highlight';

  @override
  String get highlightColorOrange => 'Orange highlight';

  @override
  String get highlightColorPink => 'Pink highlight';

  @override
  String get highlightColorsLabel => 'Lliwiau amlygu';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bible $id';
  }
}
