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
  String get searchTranslationsHint => 'Pesquisar traduções';

  @override
  String get signInFailedTitle => 'Falha ao entrar';

  @override
  String get signInFailedMessage =>
      'Algo deu errado ao entrar com o YouVersion.';

  @override
  String get closeButton => 'Fechar';

  @override
  String get tryAgainButton => 'Tentar novamente';

  @override
  String get clearHighlightTooltip => 'Limpar destaque';

  @override
  String get copyButton => 'Copiar';

  @override
  String get shareButton => 'Compartilhar';

  @override
  String get signOutNoneMessage => 'Você pode entrar novamente quando quiser.';

  @override
  String get signOutUnsyncedMessage =>
      'Alguns dos seus destaques ainda não foram salvos e serão perdidos se você sair. Deseja sair mesmo assim?';

  @override
  String get signOutTitle => 'Sair?';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get signOutButton => 'Sair';

  @override
  String get notNowButton => 'Agora não';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return 'Entrar com $brandName';
  }

  @override
  String get highlightColorYellow => 'Destaque amarelo';

  @override
  String get highlightColorGreen => 'Destaque verde';

  @override
  String get highlightColorCyan => 'Destaque ciano';

  @override
  String get highlightColorOrange => 'Destaque laranja';

  @override
  String get highlightColorPink => 'Destaque rosa';

  @override
  String get highlightColorsLabel => 'Cores de destaque';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bíblia $id';
  }
}
