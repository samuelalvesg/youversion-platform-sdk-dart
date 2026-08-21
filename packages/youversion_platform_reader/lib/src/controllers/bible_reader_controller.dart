import 'package:flutter/foundation.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

import '../navigation/chapter_navigation.dart';
import '../settings/reader_font_settings.dart';

/// Internal `ChangeNotifier` driving [BibleReader] - **not** a Riverpod/
/// state-management primitive, and not required to be used directly: an
/// app embedding [BibleReader] just gets a working reader out of the box.
/// Exposed publicly for apps that want to drive navigation externally (e.g.
/// a "jump to reference" search bar living outside the widget tree).
///
/// Ports `BibleReaderViewModel.kt`'s state shape (Kotlin) without adopting
/// its Android `ViewModel` base class - this is a plain `ChangeNotifier`,
/// Flutter's own primitive with no third-party dependency.
class BibleReaderController extends ChangeNotifier {
  BibleReaderController({
    required this.content,
    required Bible bible,
    required BibleVersionIndex index,
    required String initialChapterId,
    ReaderFontSettings fontSettings = const ReaderFontSettings(),
  })  : _bible = bible,
        _index = index,
        _chapterId = initialChapterId,
        _fontSettings = fontSettings;

  final YouVersionContentClient content;

  Bible _bible;
  BibleVersionIndex _index;
  String _chapterId;
  ReaderFontSettings _fontSettings;
  Highlight? _selectedHighlight;
  bool _isLoading = false;

  Bible get bible => _bible;
  BibleVersionIndex get index => _index;
  String get chapterId => _chapterId;
  ReaderFontSettings get fontSettings => _fontSettings;
  Highlight? get selectedHighlight => _selectedHighlight;
  bool get isLoading => _isLoading;

  bool get hasPreviousChapter => ChapterNavigation.previous(_index, _chapterId) != null;
  bool get hasNextChapter => ChapterNavigation.next(_index, _chapterId) != null;

  Future<void> goToChapter(String chapterId) async {
    _chapterId = chapterId;
    _selectedHighlight = null;
    notifyListeners();
  }

  Future<void> goToPreviousChapter() async {
    final target = ChapterNavigation.previous(_index, _chapterId);
    if (target != null) await goToChapter(target);
  }

  Future<void> goToNextChapter() async {
    final target = ChapterNavigation.next(_index, _chapterId);
    if (target != null) await goToChapter(target);
  }

  Future<void> switchBible(Bible bible, BibleVersionIndex index, String chapterId) async {
    _bible = bible;
    _index = index;
    _chapterId = chapterId;
    _selectedHighlight = null;
    notifyListeners();
  }

  void selectHighlight(Highlight? highlight) {
    _selectedHighlight = highlight;
    notifyListeners();
  }

  void updateFontSettings(ReaderFontSettings settings) {
    _fontSettings = settings;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
