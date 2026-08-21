/// Storage abstraction the reader needs (last-read reference, font/theme
/// settings, pending-highlight-request queue) - the host app implements it,
/// same "don't bundle a storage engine" principle already used by
/// `youversion_platform_core` for `installationId`.
///
/// A typical implementation wraps `shared_preferences`:
///
/// ```dart
/// class SharedPreferencesReaderStorage implements YouVersionReaderStorage {
///   @override
///   Future<String?> getString(String key) async {
///     final prefs = await SharedPreferences.getInstance();
///     return prefs.getString(key);
///   }
///
///   @override
///   Future<void> setString(String key, String value) async {
///     final prefs = await SharedPreferences.getInstance();
///     await prefs.setString(key, value);
///   }
/// }
/// ```
abstract class YouVersionReaderStorage {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

/// In-memory [YouVersionReaderStorage] - useful for tests/examples. Nothing
/// persists across process restarts.
class InMemoryReaderStorage implements YouVersionReaderStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}
