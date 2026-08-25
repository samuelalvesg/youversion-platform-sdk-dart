// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class YouVersionUiLocalizationsVi extends YouVersionUiLocalizations {
  YouVersionUiLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get verseOfTheDayLabel => 'Câu Kinh Thánh Trong Ngày';

  @override
  String get searchLanguagesHint => 'Tìm kiếm ngôn ngữ';

  @override
  String get searchTranslationsHint => 'Search translations';

  @override
  String get signInFailedTitle => 'Sign-in failed';

  @override
  String get signInFailedMessage =>
      'Something went wrong while signing in with YouVersion.';

  @override
  String get closeButton => 'Đóng';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get clearHighlightTooltip => 'Xóa đánh dấu';

  @override
  String get copyButton => 'Sao Chép';

  @override
  String get shareButton => 'Chia sẻ';

  @override
  String get signOutNoneMessage => 'You can sign back in at any time.';

  @override
  String get signOutUnsyncedMessage =>
      'Một số điểm nổi bật của bạn chưa được lưu và sẽ bị mất nếu bạn đăng xuất. Bạn có muốn đăng xuất không?';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get cancelButton => 'Hủy';

  @override
  String get signOutButton => 'Đăng xuất';

  @override
  String get notNowButton => 'Not now';

  @override
  String signInWithYouVersionLabel(String brandName) {
    return 'Đăng nhập bằng $brandName';
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
  String get highlightColorsLabel => 'Màu đánh dấu';

  @override
  String bibleIdFallbackLabel(int id) {
    return 'Bible $id';
  }
}
