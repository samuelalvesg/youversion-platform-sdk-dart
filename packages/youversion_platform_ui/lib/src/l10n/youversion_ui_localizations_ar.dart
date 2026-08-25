// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class YouVersionUiLocalizationsAr extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get verseOfTheDayLabel => 'آية اليوم';

  @override
  String get searchLanguagesHint => 'البحث في اللغات';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => 'إغلاق';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => 'مسح التمييز';

  @override
  String get copyButton => 'نسخ';

  @override
  String get shareButton => 'شارك';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage =>
      'لم يتم حفظ بعض التمييزات الخاصه بك بعد، وستُفقد إذا قمت بتسجيل الخروج. هل تريد تسجيل الخروج على أي حال؟';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get signOutButton => 'تسجيل الخروج';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return 'تسجيل الدخول باستخدام $brandName';
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
  String get highlightColorsLabel => 'ألوان التمييز';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bible $id';
  }
}
