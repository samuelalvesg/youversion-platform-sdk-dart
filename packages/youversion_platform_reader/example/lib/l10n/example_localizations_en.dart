// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'example_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ExampleLocalizationsEn extends ExampleLocalizations {
  ExampleLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appLanguageLabel => 'App language';

  @override
  String get signInTile => 'Sign In';

  @override
  String signedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get readerTile => 'Reader';

  @override
  String get readerSubtitle =>
      'BibleReader - tap-to-select, highlights, themes, footnotes';

  @override
  String get bibleExplorerTile => 'Bible Explorer';

  @override
  String get languagesTile => 'Languages';

  @override
  String get organizationsTile => 'Organizations';

  @override
  String get votdTile => 'Verse of the Day';

  @override
  String get dataExchangeTile => 'Data Exchange';

  @override
  String get signInFirst => 'Sign in first';

  @override
  String previewLabel(String sample) {
    return 'Sample _ui string: \"$sample\"';
  }

  @override
  String get signInPromptMessage =>
      'This example wants to read your profile and, if you grant it, sync highlights.';

  @override
  String get invalidUrlError => 'That doesn\'t look like a valid URL.';

  @override
  String get noCodeError =>
      'Still no \"code\" query parameter after resolving /auth/callback.';

  @override
  String get signOutButton => 'Sign out';

  @override
  String get redirectedUrlLabel => 'Redirected URL';

  @override
  String get pasteCallbackInstructions =>
      'A browser window opened. After you finish signing in, it redirects to a page this example doesn\'t control - paste the resulting URL from your browser\'s address bar below (the page itself may fail to load, that\'s expected; the \"code\" is in the URL either way).';

  @override
  String get completeSignInButton => 'Complete sign-in';

  @override
  String get signInToSyncMessage =>
      'Sign in from the \"Sign In\" section to sync highlights.';

  @override
  String get changeButton => 'Change language/version';

  @override
  String get filterByCountryTitle => 'Filter by country?';

  @override
  String get endOfListLabel => 'End of list';

  @override
  String get loadMoreButton => 'Load more';

  @override
  String idLabel(String id) {
    return 'id: $id';
  }

  @override
  String scriptLabel(String script) {
    return 'script: $script';
  }

  @override
  String textDirectionLabel(String direction) {
    return 'text direction: $direction';
  }

  @override
  String defaultBibleVersionIdLabel(String id) {
    return 'default Bible version id: $id';
  }

  @override
  String get noOrganizationsMessage =>
      'No organizations returned (try filtering by a bible_id instead).';

  @override
  String dayLabel(int day) {
    return 'Day $day';
  }

  @override
  String get dataExchangeIntro =>
      'Grants this example the \"highlights\" permission via the Data Exchange consent flow.';

  @override
  String get startDataExchangeButton => 'Start Data Exchange';

  @override
  String get pasteApprovalInstructions =>
      'After approving in the browser, paste the resulting URL here:';

  @override
  String statusLabel(String status) {
    return 'status: $status';
  }

  @override
  String grantedPermissionsLabel(String permissions) {
    return 'granted permissions: $permissions';
  }

  @override
  String get rateLimitedMessage =>
      'Too many requests - the API is rate-limiting this App Key for a bit.';

  @override
  String get signInRequiredMessage =>
      'Sign in required (or your session expired).';

  @override
  String get notPermittedMessage =>
      'Not permitted - this permission may not have been granted at sign-in.';

  @override
  String get invalidResponseMessage => 'Unexpected response from the server.';

  @override
  String requestFailedMessage(String statusCode) {
    return 'Request failed ($statusCode).';
  }

  @override
  String tryAgainInSecondsButton(int seconds) {
    return 'Try again in ${seconds}s';
  }

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get filterByCountryLabel => 'Filter by country';

  @override
  String get clearTooltip => 'Clear';

  @override
  String get copiedToClipboardMessage => 'Copied to clipboard';

  @override
  String get fontSettingsTooltip => 'Font settings';

  @override
  String get bookSectionLabel => 'Book';

  @override
  String get chapterSectionLabel => 'Chapter';

  @override
  String get verseSectionLabel => 'Verse';

  @override
  String get waitingForBrowserMessage => 'Waiting for the browser...';

  @override
  String get autoSignInButton => 'Sign in (opens browser automatically)';

  @override
  String get pickDateButton => 'Pick a date';
}
