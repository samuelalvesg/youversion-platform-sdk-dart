// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian (`no`).
class YouVersionUiLocalizationsNo extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsNo([String locale = 'no']) : super(locale);

  @override
  String get verseOfTheDayLabel => 'Dagens vers';

  @override
  String get searchLanguagesHint => 'Søk etter språk';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => 'Lukk';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => 'Fjern markering';

  @override
  String get copyButton => 'Kopier';

  @override
  String get shareButton => 'Del';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage =>
      'Du har markeringer som ikke er lagret ennå. De vil gå tapt hvis du logger ut. Vil du logge ut likevel?';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => 'Avbryt';

  @override
  String get signOutButton => 'Logg ut';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return 'Logg inn med $brandName';
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
  String get highlightColorsLabel => 'Markeringsfarger';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bible $id';
  }
}
