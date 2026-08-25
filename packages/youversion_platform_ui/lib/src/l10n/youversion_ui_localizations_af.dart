// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Afrikaans (`af`).
class YouVersionUiLocalizationsAf extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsAf([String locale = 'af']) : super(locale);

  @override
  String get verseOfTheDayLabel => 'Vers-van-die-dag';

  @override
  String get searchLanguagesHint => 'Soek tale';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => 'Sluit';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => 'Verwyder kleurmerk';

  @override
  String get copyButton => 'Kopieer';

  @override
  String get shareButton => 'Deel';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage =>
      'Sommige van jou hoogtepunte is nog nie gestoor nie, en hulle sal verlore gaan as jy uitmelú. Wil jy nogsteeds uitmeld?';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => 'Kanselleer';

  @override
  String get signOutButton => 'Teken uit';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return 'Teken in met $brandName';
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
  String get highlightColorsLabel => 'Merkkleure';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bible $id';
  }
}
