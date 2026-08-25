// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class YouVersionUiLocalizationsTr extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get verseOfTheDayLabel => 'Günün Ayeti';

  @override
  String get searchLanguagesHint => 'Dilleri ara';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => 'Kapat';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => 'Vurgulamayı temizle';

  @override
  String get copyButton => 'Kopyala';

  @override
  String get shareButton => 'Paylaş';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage =>
      'Bazı vurgulamalarınız henüz kaydedilmedi ve oturumu kapatırsanız kaybolacaklardır. Yine de oturumu kapatmak istiyor musunuz?';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => 'İptal';

  @override
  String get signOutButton => 'Çıkış yap';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return '$brandName ile giriş yap';
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
  String get highlightColorsLabel => 'Vurgulama renkleri';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bible $id';
  }
}
