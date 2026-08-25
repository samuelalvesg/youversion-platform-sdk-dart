// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class YouVersionUiLocalizationsZh extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get verseOfTheDayLabel => '今日經文';

  @override
  String get searchLanguagesHint => '搜尋語言';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => '關閉';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => '清除螢光筆';

  @override
  String get copyButton => '複製';

  @override
  String get shareButton => '分享';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage => '你部分的重點標記尚未儲存，如果你登出，這些標記將會遺失。你確定仍要登出嗎？';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => '取消';

  @override
  String get signOutButton => '登出';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return '以 $brandName登入';
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
  String get highlightColorsLabel => '螢光筆顏色';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bible $id';
  }
}
