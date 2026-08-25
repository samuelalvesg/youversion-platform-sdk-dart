// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class YouVersionUiLocalizationsPt extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get verseOfTheDayLabel => 'Versículo do Dia';

  @override
  String get searchLanguagesHint => 'Pesquisar idiomas';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => 'Fechar';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => 'Limpar destaque';

  @override
  String get copyButton => 'Copiar';

  @override
  String get shareButton => 'Compartilhar';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage =>
      'Alguns dos seus destaques ainda não foram salvos e serão perdidos se você sair. Deseja sair mesmo assim?';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get signOutButton => 'Sair';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return 'Entrar com $brandName';
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
  String get highlightColorsLabel => 'Cores de destaque';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bíblia $id';
  }
}
