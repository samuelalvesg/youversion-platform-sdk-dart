// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'example_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class ExampleLocalizationsPt extends ExampleLocalizations {
  ExampleLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appLanguageLabel => 'Idioma do app';

  @override
  String get signInTile => 'Entrar';

  @override
  String signedInAs(String name) {
    return 'Conectado como $name';
  }

  @override
  String get notSignedIn => 'Não conectado';

  @override
  String get readerTile => 'Leitor';

  @override
  String get readerSubtitle =>
      'BibleReader - toque para selecionar, marcações, temas, notas de rodapé';

  @override
  String get bibleExplorerTile => 'Explorador de Bíblia';

  @override
  String get languagesTile => 'Idiomas';

  @override
  String get organizationsTile => 'Organizações';

  @override
  String get votdTile => 'Versículo do Dia';

  @override
  String get dataExchangeTile => 'Troca de Dados';

  @override
  String get signInFirst => 'Entre na conta primeiro';

  @override
  String previewLabel(String sample) {
    return 'Exemplo de string do _ui: \"$sample\"';
  }

  @override
  String get signInPromptMessage =>
      'Este exemplo quer ler seu perfil e, se você permitir, sincronizar marcações.';

  @override
  String get invalidUrlError => 'Isso não parece uma URL válida.';

  @override
  String get noCodeError =>
      'Ainda sem o parâmetro \"code\" depois de resolver /auth/callback.';

  @override
  String get signOutButton => 'Sair';

  @override
  String get redirectedUrlLabel => 'URL redirecionada';

  @override
  String get pasteCallbackInstructions =>
      'Uma janela do navegador abriu. Depois de terminar o login, ela redireciona pra uma página que este exemplo não controla - cole a URL resultante da barra de endereço do navegador abaixo (a página em si pode falhar ao carregar, isso é esperado; o \"code\" está na URL de qualquer forma).';

  @override
  String get completeSignInButton => 'Concluir login';

  @override
  String get signInToSyncMessage =>
      'Entre na seção \"Entrar\" pra sincronizar marcações.';

  @override
  String get filterByCountryTitle => 'Filtrar por país?';

  @override
  String get endOfListLabel => 'Fim da lista';

  @override
  String get loadMoreButton => 'Carregar mais';

  @override
  String idLabel(String id) {
    return 'id: $id';
  }

  @override
  String scriptLabel(String script) {
    return 'escrita: $script';
  }

  @override
  String textDirectionLabel(String direction) {
    return 'direção do texto: $direction';
  }

  @override
  String defaultBibleVersionIdLabel(String id) {
    return 'id da versão padrão da Bíblia: $id';
  }

  @override
  String get noOrganizationsMessage =>
      'Nenhuma organização retornada (tente filtrar por um bible_id).';

  @override
  String dayLabel(int day) {
    return 'Dia $day';
  }

  @override
  String get dataExchangeIntro =>
      'Concede a este exemplo a permissão \"highlights\" via o fluxo de consentimento do Data Exchange.';

  @override
  String get startDataExchangeButton => 'Iniciar Data Exchange';

  @override
  String get pasteApprovalInstructions =>
      'Depois de aprovar no navegador, cole a URL resultante aqui:';

  @override
  String statusLabel(String status) {
    return 'status: $status';
  }

  @override
  String grantedPermissionsLabel(String permissions) {
    return 'permissões concedidas: $permissions';
  }

  @override
  String get rateLimitedMessage =>
      'Muitas requisições - a API está limitando esta App Key por um tempo.';

  @override
  String get signInRequiredMessage =>
      'É preciso entrar na conta (ou sua sessão expirou).';

  @override
  String get notPermittedMessage =>
      'Não permitido - essa permissão pode não ter sido concedida no login.';

  @override
  String get invalidResponseMessage => 'Resposta inesperada do servidor.';

  @override
  String requestFailedMessage(String statusCode) {
    return 'Requisição falhou ($statusCode).';
  }

  @override
  String tryAgainInSecondsButton(int seconds) {
    return 'Tentar de novo em ${seconds}s';
  }

  @override
  String get tryAgainButton => 'Tentar de novo';

  @override
  String get filterByCountryLabel => 'Filtrar por país';

  @override
  String get clearTooltip => 'Limpar';

  @override
  String get copiedToClipboardMessage => 'Copiado pra área de transferência';

  @override
  String get fontSettingsTooltip => 'Configurações de fonte';

  @override
  String get bookSectionLabel => 'Livro';

  @override
  String get chapterSectionLabel => 'Capítulo';

  @override
  String get verseSectionLabel => 'Versículo';

  @override
  String get waitingForBrowserMessage => 'Aguardando o navegador...';

  @override
  String get autoSignInButton => 'Entrar (abre o navegador automaticamente)';

  @override
  String get pickDateButton => 'Escolher data';

  @override
  String get previousChapterButton => 'Capítulo anterior';

  @override
  String get nextChapterButton => 'Próximo capítulo';
}
