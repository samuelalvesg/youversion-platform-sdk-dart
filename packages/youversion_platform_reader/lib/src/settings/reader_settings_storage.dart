import 'dart:convert';

import '../storage/youversion_reader_storage.dart';
import 'reader_font_settings.dart';

/// Persists/restores [ReaderFontSettings] via [YouVersionReaderStorage].
class ReaderSettingsStorage {
  ReaderSettingsStorage(this._storage, {this.storageKey = 'youversion_reader_font_settings'});

  final YouVersionReaderStorage _storage;
  final String storageKey;

  Future<ReaderFontSettings> load() async {
    final raw = await _storage.getString(storageKey);
    if (raw == null) return const ReaderFontSettings();
    return ReaderFontSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(ReaderFontSettings settings) {
    return _storage.setString(storageKey, jsonEncode(settings.toJson()));
  }
}
