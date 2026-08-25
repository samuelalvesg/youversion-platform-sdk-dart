import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'youversion_reader_localizations_af.dart';
import 'youversion_reader_localizations_ar.dart';
import 'youversion_reader_localizations_cs.dart';
import 'youversion_reader_localizations_cy.dart';
import 'youversion_reader_localizations_de.dart';
import 'youversion_reader_localizations_en.dart';
import 'youversion_reader_localizations_es.dart';
import 'youversion_reader_localizations_fr.dart';
import 'youversion_reader_localizations_ko.dart';
import 'youversion_reader_localizations_no.dart';
import 'youversion_reader_localizations_pt.dart';
import 'youversion_reader_localizations_tr.dart';
import 'youversion_reader_localizations_vi.dart';
import 'youversion_reader_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of YouVersionReaderLocalizations
/// returned by `YouVersionReaderLocalizations.of(context)`.
///
/// Applications need to include `YouVersionReaderLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/youversion_reader_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: YouVersionReaderLocalizations.localizationsDelegates,
///   supportedLocales: YouVersionReaderLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the YouVersionReaderLocalizations.supportedLocales
/// property.
abstract class YouVersionReaderLocalizations {
  YouVersionReaderLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static YouVersionReaderLocalizations of(BuildContext context) {
    return Localizations.of<YouVersionReaderLocalizations>(
        context, YouVersionReaderLocalizations)!;
  }

  static const LocalizationsDelegate<YouVersionReaderLocalizations> delegate =
      _YouVersionReaderLocalizationsDelegate();

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
    Locale('af'),
    Locale('ar'),
    Locale('cs'),
    Locale('cy'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ko'),
    Locale('no'),
    Locale('pt'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @bibleFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Bible'**
  String get bibleFallbackTitle;

  /// No description provided for @fontSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Font settings'**
  String get fontSettingsTooltip;

  /// No description provided for @fontSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSizeLabel;

  /// No description provided for @lineSpacingLabel.
  ///
  /// In en, this message translates to:
  /// **'Line spacing'**
  String get lineSpacingLabel;

  /// No description provided for @searchBooksHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchBooksHint;

  /// No description provided for @introChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Intro'**
  String get introChipLabel;

  /// No description provided for @previousChapterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get previousChapterTooltip;

  /// No description provided for @nextChapterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get nextChapterTooltip;

  /// No description provided for @decreaseFontSizeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Decrease font size'**
  String get decreaseFontSizeTooltip;

  /// No description provided for @increaseFontSizeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Increase font size'**
  String get increaseFontSizeTooltip;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themePureWhite.
  ///
  /// In en, this message translates to:
  /// **'Pure White'**
  String get themePureWhite;

  /// No description provided for @themeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get themeSepia;

  /// No description provided for @themePaperGray.
  ///
  /// In en, this message translates to:
  /// **'Paper Gray'**
  String get themePaperGray;

  /// No description provided for @themeCream.
  ///
  /// In en, this message translates to:
  /// **'Cream'**
  String get themeCream;

  /// No description provided for @themeMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get themeMint;

  /// No description provided for @themeSkyBlue.
  ///
  /// In en, this message translates to:
  /// **'Sky Blue'**
  String get themeSkyBlue;

  /// No description provided for @themeCharcoal.
  ///
  /// In en, this message translates to:
  /// **'Charcoal'**
  String get themeCharcoal;

  /// No description provided for @themeMidnightBlue.
  ///
  /// In en, this message translates to:
  /// **'Midnight Blue'**
  String get themeMidnightBlue;

  /// No description provided for @themeTrueBlack.
  ///
  /// In en, this message translates to:
  /// **'True Black'**
  String get themeTrueBlack;

  /// No description provided for @themeGraphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get themeGraphite;

  /// No description provided for @themeForestNight.
  ///
  /// In en, this message translates to:
  /// **'Forest Night'**
  String get themeForestNight;

  /// No description provided for @bionicReadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Bionic Reading'**
  String get bionicReadingLabel;

  /// No description provided for @changeVersionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change Bible version'**
  String get changeVersionTooltip;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButton;

  /// Shown when a chapter load fails with YouVersionErrorReason.rateLimited (HTTP 429).
  ///
  /// In en, this message translates to:
  /// **'Too many requests - please wait a bit before trying again.'**
  String get rateLimitedError;

  /// Shown when a chapter load fails with YouVersionErrorReason.missingAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Sign in required (or your session expired).'**
  String get signInRequiredError;

  /// Shown when a chapter load fails with YouVersionErrorReason.notPermitted.
  ///
  /// In en, this message translates to:
  /// **'Not permitted for this account.'**
  String get notPermittedError;

  /// Shown when a chapter load fails with YouVersionErrorReason.invalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response from the server.'**
  String get invalidResponseError;

  /// Generic fallback shown when a chapter load fails for any other reason.
  ///
  /// In en, this message translates to:
  /// **'Could not load this chapter.'**
  String get loadFailedError;
}

class _YouVersionReaderLocalizationsDelegate
    extends LocalizationsDelegate<YouVersionReaderLocalizations> {
  const _YouVersionReaderLocalizationsDelegate();

  @override
  Future<YouVersionReaderLocalizations> load(Locale locale) {
    return SynchronousFuture<YouVersionReaderLocalizations>(
        lookupYouVersionReaderLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'af',
        'ar',
        'cs',
        'cy',
        'de',
        'en',
        'es',
        'fr',
        'ko',
        'no',
        'pt',
        'tr',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_YouVersionReaderLocalizationsDelegate old) => false;
}

YouVersionReaderLocalizations lookupYouVersionReaderLocalizations(
    Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af':
      return YouVersionReaderLocalizationsAf();
    case 'ar':
      return YouVersionReaderLocalizationsAr();
    case 'cs':
      return YouVersionReaderLocalizationsCs();
    case 'cy':
      return YouVersionReaderLocalizationsCy();
    case 'de':
      return YouVersionReaderLocalizationsDe();
    case 'en':
      return YouVersionReaderLocalizationsEn();
    case 'es':
      return YouVersionReaderLocalizationsEs();
    case 'fr':
      return YouVersionReaderLocalizationsFr();
    case 'ko':
      return YouVersionReaderLocalizationsKo();
    case 'no':
      return YouVersionReaderLocalizationsNo();
    case 'pt':
      return YouVersionReaderLocalizationsPt();
    case 'tr':
      return YouVersionReaderLocalizationsTr();
    case 'vi':
      return YouVersionReaderLocalizationsVi();
    case 'zh':
      return YouVersionReaderLocalizationsZh();
  }

  throw FlutterError(
      'YouVersionReaderLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
