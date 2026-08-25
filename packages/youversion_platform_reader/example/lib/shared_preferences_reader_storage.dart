import 'package:shared_preferences/shared_preferences.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';

/// Real, persistent [YouVersionReaderStorage] - font/theme settings and the
/// pending-highlight queue now survive an app restart, unlike
/// `InMemoryReaderStorage`. Matches the `shared_preferences`-backed example
/// already given in [YouVersionReaderStorage]'s own doc comment.
class SharedPreferencesReaderStorage implements YouVersionReaderStorage {
  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
