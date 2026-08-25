// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'youversion_reader_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class YouVersionReaderLocalizationsKo extends YouVersionReaderLocalizations {
  YouVersionReaderLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get bibleFallbackTitle => 'Bible';

  @override
  String get fontSettingsTooltip => 'Font settings';

  @override
  String get fontSizeLabel => 'Font size';

  @override
  String get lineSpacingLabel => 'Line spacing';

  @override
  String get searchBooksHint => '찾기';

  @override
  String get introChipLabel => 'Intro';

  @override
  String get previousChapterTooltip => '이전 장';

  @override
  String get nextChapterTooltip => '다음 장';

  @override
  String get decreaseFontSizeTooltip => '글꼴 크기 줄이기';

  @override
  String get increaseFontSizeTooltip => '글꼴 크기 늘리기';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themePureWhite => 'Pure White';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get themePaperGray => 'Paper Gray';

  @override
  String get themeCream => 'Cream';

  @override
  String get themeCharcoal => 'Charcoal';

  @override
  String get themeMidnightBlue => 'Midnight Blue';

  @override
  String get themeTrueBlack => 'True Black';

  @override
  String get changeVersionTooltip => '번역본 변경';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get rateLimitedError =>
      'Too many requests - please wait a bit before trying again.';

  @override
  String get signInRequiredError =>
      'Sign in required (or your session expired).';

  @override
  String get notPermittedError => 'Not permitted for this account.';

  @override
  String get invalidResponseError => 'Unexpected response from the server.';

  @override
  String get loadFailedError => 'Could not load this chapter.';
}
