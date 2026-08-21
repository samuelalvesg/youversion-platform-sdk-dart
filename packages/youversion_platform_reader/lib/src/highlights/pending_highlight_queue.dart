import 'dart:convert';

import 'package:youversion_platform_core/youversion_platform_core.dart';

import '../storage/youversion_reader_storage.dart';

/// A highlight requested while signed out, or before the `highlights`
/// permission was granted.
class PendingHighlightRequest {
  const PendingHighlightRequest({required this.bibleId, required this.passageId, required this.color});

  final int bibleId;
  final String passageId;
  final String color;

  Map<String, dynamic> toJson() => {'bible_id': bibleId, 'passage_id': passageId, 'color': color};

  factory PendingHighlightRequest.fromJson(Map<String, dynamic> json) {
    return PendingHighlightRequest(
      bibleId: json['bible_id'] as int,
      passageId: json['passage_id'] as String,
      color: json['color'] as String,
    );
  }
}

/// Queues highlight requests made without authentication/permission, and
/// replays them once sign-in/consent completes - ports the offline-request
/// idea from Kotlin's `HighlightRequest` (`platform-reader`) and RN/Expo's
/// equivalent queue. Persisted via [YouVersionReaderStorage] so it survives
/// process death, not just an in-memory list.
class PendingHighlightQueue {
  PendingHighlightQueue(this._storage, {this.storageKey = 'youversion_pending_highlights'});

  final YouVersionReaderStorage _storage;
  final String storageKey;

  Future<List<PendingHighlightRequest>> load() async {
    final raw = await _storage.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((item) => PendingHighlightRequest.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> _save(List<PendingHighlightRequest> requests) {
    return _storage.setString(storageKey, jsonEncode(requests.map((r) => r.toJson()).toList()));
  }

  Future<void> enqueue(PendingHighlightRequest request) async {
    final requests = [...await load(), request];
    await _save(requests);
  }

  /// Replays every queued request against [client] using [userAccessToken],
  /// then clears the queue. Requests that fail are dropped rather than
  /// retried indefinitely - a stale bible/passage id shouldn't block the
  /// rest of the queue forever.
  Future<void> replay({
    required YouVersionHighlightsClient client,
    required String userAccessToken,
  }) async {
    final requests = await load();
    if (requests.isEmpty) return;

    for (final request in requests) {
      try {
        await client.createHighlight(
          userAccessToken: userAccessToken,
          bibleId: request.bibleId,
          passageId: request.passageId,
          color: request.color,
        );
      } on YouVersionException {
        // Drop and move on - see method doc comment.
      }
    }

    await _save(const []);
  }
}
