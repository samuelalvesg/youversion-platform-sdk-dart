// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class YouVersionUiLocalizationsEs extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get verseOfTheDayLabel => 'Versículo del Día';

  @override
  String get searchLanguagesHint => 'Buscar idiomas';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => 'Cerca';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => 'Borrar resaltado';

  @override
  String get copyButton => 'Copiar';

  @override
  String get shareButton => 'Compartir';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage =>
      'Algunos de tus resaltados no se han guardado aún y se perderán si cierras sesión. ¿Deseas cerrar sesión de todas formas?';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get signOutButton => 'Cerrar sesión';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return 'Iniciar sesión con $brandName';
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
  String get highlightColorsLabel => 'Colores de resaltado';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bible $id';
  }
}
