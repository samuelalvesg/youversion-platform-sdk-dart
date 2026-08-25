// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class YouVersionUiLocalizationsCs extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get verseOfTheDayLabel => 'Verš dne';

  @override
  String get searchLanguagesHint => 'Hledat jazyky';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => 'Zavřít';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => 'Vymazat zvýraznění';

  @override
  String get copyButton => 'Kopírovat';

  @override
  String get shareButton => 'Sdílet';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage =>
      'Některá vaše zvýraznění ještě nebyla uložena a budou ztracena, pokud se odhlásíte. Chcete se přesto odhlásit?';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => 'Zrušit';

  @override
  String get signOutButton => 'Odhlášení';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return 'Přihlásit se pomocí $brandName';
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
  String get highlightColorsLabel => 'Barvy zvýraznění';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bible $id';
  }
}
