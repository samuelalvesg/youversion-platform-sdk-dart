// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class YouVersionUiLocalizationsKo extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get verseOfTheDayLabel => '오늘의 말씀';

  @override
  String get searchLanguagesHint => '언어 검색';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => '닫기';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => '하이라이트 지우기';

  @override
  String get copyButton => '복사';

  @override
  String get shareButton => '공유';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage =>
      '일부 하이라이트가 아직 저장되지 않았으며, 로그아웃하면 삭제됩니다. 그래도 로그아웃하시겠습니까?';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => '취소';

  @override
  String get signOutButton => '로그아웃';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return '$brandName 서비스로 로그인';
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
  String get highlightColorsLabel => '하이라이트 색상';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bible $id';
  }
}
