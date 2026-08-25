// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class YouVersionUiLocalizationsDe extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get verseOfTheDayLabel => 'Vers des Tages';

  @override
  String get searchLanguagesHint => 'Sprachen suchen';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => 'Schließen';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => 'Hervorhebung entfernen';

  @override
  String get copyButton => 'Kopieren';

  @override
  String get shareButton => 'Teilen';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage =>
      'Einige deiner Markierungen wurden noch nicht gespeichert und gehen verloren, wenn du dich abmeldest. Möchtest du dich trotzdem abmelden?';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get signOutButton => 'Abmelden';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return 'Anmelden mit $brandName';
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
  String get highlightColorsLabel => 'Hervorhebungsfarben';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bible $id';
  }
}
