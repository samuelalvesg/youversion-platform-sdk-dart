// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class YouVersionUiLocalizationsFr extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get verseOfTheDayLabel => 'Verset du Jour';

  @override
  String get searchLanguagesHint => 'Search languages';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => 'Close';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => 'Supprimer le surlignage';

  @override
  String get copyButton => 'Copier';

  @override
  String get shareButton => 'Partager';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage =>
      'Some of your highlights haven\'t been saved yet, and they will be lost if you sign out. Do you want to sign out anyway?';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get signOutButton => 'Se déconnecter';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return 'Se connecter avec $brandName';
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
  String get highlightColorsLabel => 'Couleurs de surlignage';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bible $id';
  }
}
