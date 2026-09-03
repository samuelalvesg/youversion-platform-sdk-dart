import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'example_localizations_en.dart';
import 'example_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ExampleLocalizations
/// returned by `ExampleLocalizations.of(context)`.
///
/// Applications need to include `ExampleLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/example_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ExampleLocalizations.localizationsDelegates,
///   supportedLocales: ExampleLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ExampleLocalizations.supportedLocales
/// property.
abstract class ExampleLocalizations {
  ExampleLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ExampleLocalizations of(BuildContext context) {
    return Localizations.of<ExampleLocalizations>(
        context, ExampleLocalizations)!;
  }

  static const LocalizationsDelegate<ExampleLocalizations> delegate =
      _ExampleLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguageLabel;

  /// No description provided for @signInTile.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTile;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String signedInAs(String name);

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @readerTile.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get readerTile;

  /// No description provided for @readerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'BibleReader - tap-to-select, highlights, themes, footnotes'**
  String get readerSubtitle;

  /// No description provided for @bibleExplorerTile.
  ///
  /// In en, this message translates to:
  /// **'Bible Explorer'**
  String get bibleExplorerTile;

  /// No description provided for @languagesTile.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesTile;

  /// No description provided for @organizationsTile.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get organizationsTile;

  /// No description provided for @votdTile.
  ///
  /// In en, this message translates to:
  /// **'Verse of the Day'**
  String get votdTile;

  /// No description provided for @dataExchangeTile.
  ///
  /// In en, this message translates to:
  /// **'Data Exchange'**
  String get dataExchangeTile;

  /// No description provided for @signInFirst.
  ///
  /// In en, this message translates to:
  /// **'Sign in first'**
  String get signInFirst;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Sample _ui string: \"{sample}\"'**
  String previewLabel(String sample);

  /// No description provided for @signInPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'This example wants to read your profile and, if you grant it, sync highlights.'**
  String get signInPromptMessage;

  /// No description provided for @invalidUrlError.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a valid URL.'**
  String get invalidUrlError;

  /// No description provided for @noCodeError.
  ///
  /// In en, this message translates to:
  /// **'Still no \"code\" query parameter after resolving /auth/callback.'**
  String get noCodeError;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutButton;

  /// No description provided for @redirectedUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Redirected URL'**
  String get redirectedUrlLabel;

  /// No description provided for @pasteCallbackInstructions.
  ///
  /// In en, this message translates to:
  /// **'A browser window opened. After you finish signing in, it redirects to a page this example doesn\'t control - paste the resulting URL from your browser\'s address bar below (the page itself may fail to load, that\'s expected; the \"code\" is in the URL either way).'**
  String get pasteCallbackInstructions;

  /// No description provided for @completeSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Complete sign-in'**
  String get completeSignInButton;

  /// No description provided for @signInToSyncMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in from the \"Sign In\" section to sync highlights.'**
  String get signInToSyncMessage;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session expired - sign in again to sync highlights.'**
  String get sessionExpiredMessage;

  /// No description provided for @filterByCountryTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by country?'**
  String get filterByCountryTitle;

  /// No description provided for @endOfListLabel.
  ///
  /// In en, this message translates to:
  /// **'End of list'**
  String get endOfListLabel;

  /// No description provided for @loadMoreButton.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMoreButton;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'id: {id}'**
  String idLabel(String id);

  /// No description provided for @scriptLabel.
  ///
  /// In en, this message translates to:
  /// **'script: {script}'**
  String scriptLabel(String script);

  /// No description provided for @textDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'text direction: {direction}'**
  String textDirectionLabel(String direction);

  /// No description provided for @defaultBibleVersionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'default Bible version id: {id}'**
  String defaultBibleVersionIdLabel(String id);

  /// No description provided for @noOrganizationsMessage.
  ///
  /// In en, this message translates to:
  /// **'No organizations returned (try filtering by a bible_id instead).'**
  String get noOrganizationsMessage;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String dayLabel(int day);

  /// No description provided for @dataExchangeIntro.
  ///
  /// In en, this message translates to:
  /// **'Grants this example the \"highlights\" permission via the Data Exchange consent flow.'**
  String get dataExchangeIntro;

  /// No description provided for @startDataExchangeButton.
  ///
  /// In en, this message translates to:
  /// **'Start Data Exchange'**
  String get startDataExchangeButton;

  /// No description provided for @pasteApprovalInstructions.
  ///
  /// In en, this message translates to:
  /// **'After approving in the browser, paste the resulting URL here:'**
  String get pasteApprovalInstructions;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'status: {status}'**
  String statusLabel(String status);

  /// No description provided for @grantedPermissionsLabel.
  ///
  /// In en, this message translates to:
  /// **'granted permissions: {permissions}'**
  String grantedPermissionsLabel(String permissions);

  /// No description provided for @rateLimitedMessage.
  ///
  /// In en, this message translates to:
  /// **'Too many requests - the API is rate-limiting this App Key for a bit.'**
  String get rateLimitedMessage;

  /// No description provided for @signInRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in required (or your session expired).'**
  String get signInRequiredMessage;

  /// No description provided for @notPermittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Not permitted - this permission may not have been granted at sign-in.'**
  String get notPermittedMessage;

  /// No description provided for @invalidResponseMessage.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response from the server.'**
  String get invalidResponseMessage;

  /// No description provided for @requestFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Request failed ({statusCode}).'**
  String requestFailedMessage(String statusCode);

  /// No description provided for @tryAgainInSecondsButton.
  ///
  /// In en, this message translates to:
  /// **'Try again in {seconds}s'**
  String tryAgainInSecondsButton(int seconds);

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButton;

  /// No description provided for @filterByCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter by country'**
  String get filterByCountryLabel;

  /// No description provided for @clearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearTooltip;

  /// No description provided for @copiedToClipboardMessage.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboardMessage;

  /// No description provided for @fontSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Font settings'**
  String get fontSettingsTooltip;

  /// No description provided for @bookSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get bookSectionLabel;

  /// No description provided for @chapterSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get chapterSectionLabel;

  /// No description provided for @verseSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Verse'**
  String get verseSectionLabel;

  /// No description provided for @waitingForBrowserMessage.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the browser...'**
  String get waitingForBrowserMessage;

  /// No description provided for @autoSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in (opens browser automatically)'**
  String get autoSignInButton;

  /// No description provided for @pickDateButton.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDateButton;

  /// No description provided for @previousChapterButton.
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get previousChapterButton;

  /// No description provided for @nextChapterButton.
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get nextChapterButton;
}

class _ExampleLocalizationsDelegate
    extends LocalizationsDelegate<ExampleLocalizations> {
  const _ExampleLocalizationsDelegate();

  @override
  Future<ExampleLocalizations> load(Locale locale) {
    return SynchronousFuture<ExampleLocalizations>(
        lookupExampleLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_ExampleLocalizationsDelegate old) => false;
}

ExampleLocalizations lookupExampleLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ExampleLocalizationsEn();
    case 'pt':
      return ExampleLocalizationsPt();
  }

  throw FlutterError(
      'ExampleLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
