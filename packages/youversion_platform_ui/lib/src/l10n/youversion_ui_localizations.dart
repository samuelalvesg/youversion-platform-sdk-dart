import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'youversion_ui_localizations_af.dart';
import 'youversion_ui_localizations_ar.dart';
import 'youversion_ui_localizations_cs.dart';
import 'youversion_ui_localizations_cy.dart';
import 'youversion_ui_localizations_de.dart';
import 'youversion_ui_localizations_en.dart';
import 'youversion_ui_localizations_es.dart';
import 'youversion_ui_localizations_fr.dart';
import 'youversion_ui_localizations_ko.dart';
import 'youversion_ui_localizations_no.dart';
import 'youversion_ui_localizations_pt.dart';
import 'youversion_ui_localizations_tr.dart';
import 'youversion_ui_localizations_vi.dart';
import 'youversion_ui_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of YouVersionUiLocalizations
/// returned by `YouVersionUiLocalizations.of(context)`.
///
/// Applications need to include `YouVersionUiLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/youversion_ui_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: YouVersionUiLocalizations.localizationsDelegates,
///   supportedLocales: YouVersionUiLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the YouVersionUiLocalizations.supportedLocales
/// property.
abstract class YouVersionUiLocalizations {
  YouVersionUiLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static YouVersionUiLocalizations of(BuildContext context) {
    return Localizations.of<YouVersionUiLocalizations>(
        context, YouVersionUiLocalizations)!;
  }

  static const LocalizationsDelegate<YouVersionUiLocalizations> delegate =
      _YouVersionUiLocalizationsDelegate();

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

  /// Eyebrow label above a verse-of-the-day card. Rendered upper-case by the widget.
  ///
  /// In en, this message translates to:
  /// **'Verse of The Day'**
  String get verseOfTheDayLabel;

  /// No description provided for @searchLanguagesHint.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get searchLanguagesHint;

  /// No description provided for @searchTranslationsHint.
  ///
  /// In en, this message translates to:
  /// **'Search translations'**
  String get searchTranslationsHint;

  /// No description provided for @signInFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed'**
  String get signInFailedTitle;

  /// No description provided for @signInFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while signing in with YouVersion.'**
  String get signInFailedMessage;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButton;

  /// No description provided for @clearHighlightTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear highlight'**
  String get clearHighlightTooltip;

  /// No description provided for @copyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyButton;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @signOutNoneMessage.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in at any time.'**
  String get signOutNoneMessage;

  /// No description provided for @signOutUnsyncedMessage.
  ///
  /// In en, this message translates to:
  /// **'Some of your highlights haven\'t been saved yet, and they will be lost if you sign out. Do you want to sign out anyway?'**
  String get signOutUnsyncedMessage;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutButton;

  /// No description provided for @notNowButton.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNowButton;

  /// No description provided for @signInWithYouVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign in with {brandName}'**
  String signInWithYouVersionLabel(String brandName);

  /// No description provided for @highlightColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow highlight'**
  String get highlightColorYellow;

  /// No description provided for @highlightColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green highlight'**
  String get highlightColorGreen;

  /// No description provided for @highlightColorCyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan highlight'**
  String get highlightColorCyan;

  /// No description provided for @highlightColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange highlight'**
  String get highlightColorOrange;

  /// No description provided for @highlightColorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink highlight'**
  String get highlightColorPink;

  /// No description provided for @highlightColorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Highlight colors'**
  String get highlightColorsLabel;

  /// Fallback label for a Bible with no title/abbreviation available.
  ///
  /// In en, this message translates to:
  /// **'Bible {id}'**
  String bibleIdFallbackLabel(int id);
}

class _YouVersionUiLocalizationsDelegate
    extends LocalizationsDelegate<YouVersionUiLocalizations> {
  const _YouVersionUiLocalizationsDelegate();

  @override
  Future<YouVersionUiLocalizations> load(Locale locale) {
    return SynchronousFuture<YouVersionUiLocalizations>(
        lookupYouVersionUiLocalizations(locale));
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
  bool shouldReload(_YouVersionUiLocalizationsDelegate old) => false;
}

YouVersionUiLocalizations lookupYouVersionUiLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af':
      return YouVersionUiLocalizationsAf();
    case 'ar':
      return YouVersionUiLocalizationsAr();
    case 'cs':
      return YouVersionUiLocalizationsCs();
    case 'cy':
      return YouVersionUiLocalizationsCy();
    case 'de':
      return YouVersionUiLocalizationsDe();
    case 'en':
      return YouVersionUiLocalizationsEn();
    case 'es':
      return YouVersionUiLocalizationsEs();
    case 'fr':
      return YouVersionUiLocalizationsFr();
    case 'ko':
      return YouVersionUiLocalizationsKo();
    case 'no':
      return YouVersionUiLocalizationsNo();
    case 'pt':
      return YouVersionUiLocalizationsPt();
    case 'tr':
      return YouVersionUiLocalizationsTr();
    case 'vi':
      return YouVersionUiLocalizationsVi();
    case 'zh':
      return YouVersionUiLocalizationsZh();
  }

  throw FlutterError(
      'YouVersionUiLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
