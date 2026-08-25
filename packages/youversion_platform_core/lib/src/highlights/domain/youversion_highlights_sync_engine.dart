import 'dart:async';

import '../../http/youversion_exception.dart';
import '../api/youversion_highlights_client.dart';
import '../models/highlight.dart';

/// Default retry backoff: `min(2^min(retryCount, 5), 30)` seconds - ported
/// verbatim from platform-sdk-kotlin's `BibleHighlightsRepository.backoffMillis`.
Duration _defaultBackoff(int retryCount) {
  final exponent = retryCount < 5 ? retryCount : 5;
  final seconds = 1 << exponent;
  return Duration(seconds: seconds > 30 ? 30 : seconds);
}

class _PendingOperation {
  _PendingOperation({
    required this.id,
    required this.bibleId,
    required this.chapterId,
    required this.passageId,
    required this.color,
    required this.generation,
  });

  final int id;
  final int bibleId;
  final String chapterId;
  final String passageId;

  /// `null` = remove, non-null = create-or-recolor (matches Kotlin's
  /// `HighlightChange.SetColor`/`Remove` - one write shape, not 3).
  final String? color;
  final int generation;
  int retryCount = 0;
}

/// In-memory, offline-aware sync layer on top of [YouVersionHighlightsClient]
/// - optimistic local writes, a retry queue with exponential backoff,
/// per-account-permission-refusal (`403`) handling that doesn't wedge the
/// queue, per-chapter load throttling/deduplication, and session-scoped
/// invalidation via [reset]. Ported from platform-sdk-kotlin's
/// `highlights/domain/BibleHighlightsRepository.kt` +
/// `BibleHighlightCache.kt`, adapted to Dart:
///
/// - No `Mutex` - Dart's single-threaded event loop makes plain
///   synchronous map/list mutation race-free at the points that matter
///   (same reasoning as `YouVersionContentClient`'s dedup+cache).
/// - No `StateFlow` per query - a single broadcast [changes] stream fires
///   on every observable mutation; callers re-read the synchronous
///   getters ([highlightsForChapter], [pendingOperationCount],
///   [failedOperationCount]) afterward. Simpler than porting a reactive
///   stream per query, still reactive enough to drive a `setState`.
/// - No structured `BibleReference` type - this package deliberately
///   doesn't have USFM range parsing (see `BACKLOG.md`), so operations
///   are keyed directly on the `bibleId`/`passageId` (verse-level USFM,
///   e.g. `JHN.3.16`) vocabulary [YouVersionHighlightsClient] already
///   uses, plus an explicit `chapterId` (e.g. `JHN.3`) passed by the
///   caller for the load-throttle key - not derived by parsing
///   `passageId`.
///
/// **In-memory only, cleared on [close]** - like the content-client
/// dedup+cache, this is not the "offline content cache" this package
/// deliberately doesn't implement (see `docs/DECISIONS.md`'s
/// "storage-agnostic" principle). Kotlin's own queue is equally
/// memory-only ("lost on process death"). For surviving an app restart
/// while signed out, see `youversion_platform_reader`'s
/// `PendingHighlightQueue` - a separate, complementary concern (queued
/// across restarts) this engine doesn't attempt.
///
/// This package has no global session/config singleton (unlike Kotlin's
/// `YouVersionPlatformConfiguration`), so there's nothing for this engine
/// to observe automatically on sign-out/account-switch - call [reset]
/// explicitly when that happens.
class YouVersionHighlightsSyncEngine {
  YouVersionHighlightsSyncEngine({
    required YouVersionHighlightsClient client,
    required String? Function() accessToken,
    this.chapterLoadThrottle = const Duration(minutes: 5),
    Duration Function(int retryCount)? backoff,
  })  : _client = client,
        _accessToken = accessToken,
        _backoff = backoff ?? _defaultBackoff;

  final YouVersionHighlightsClient _client;

  /// Re-invoked on every send/retry attempt (not captured once) so the
  /// engine always uses the current sign-in/refreshed token. `null` means
  /// signed out - operations stay queued (as failures, retried like any
  /// other transient failure) until a real token is available again.
  final String? Function() _accessToken;

  final Duration chapterLoadThrottle;
  final Duration Function(int retryCount) _backoff;

  final _changesController = StreamController<void>.broadcast();

  /// Fires after any observable mutation (a highlight applied/removed
  /// locally or received from the server, the pending/failed operation
  /// count changed, a chapter finished loading). Re-read the synchronous
  /// getters after an event - this stream carries no payload.
  Stream<void> get changes => _changesController.stream;

  void _notify() {
    if (!_changesController.isClosed) _changesController.add(null);
  }

  final Map<String, Map<String, Highlight>> _highlightsByChapter = {};
  final Set<String> _serverBackedPassageIds = {};
  final Map<String, DateTime> _lastChapterFetch = {};
  final Map<String, Future<void>> _chapterLoadInFlight = {};

  final List<_PendingOperation> _queue = [];
  int _failedOperationCount = 0;
  int _nextOperationId = 0;
  int _generation = 0;
  bool _isProcessing = false;
  bool _closed = false;

  String _chapterKey(int bibleId, String chapterId) => '$bibleId:$chapterId';
  String _passageKey(int bibleId, String passageId) => '$bibleId:$passageId';

  /// Current local (optimistic) view of a chapter's highlights - call
  /// [ensureLoaded] first to populate it from the server.
  List<Highlight> highlightsForChapter({required int bibleId, required String chapterId}) {
    final map = _highlightsByChapter[_chapterKey(bibleId, chapterId)];
    return map == null ? const [] : map.values.toList(growable: false);
  }

  int get pendingOperationCount => _queue.length;
  int get failedOperationCount => _failedOperationCount;
  bool get hasPendingOperations => _queue.isNotEmpty || _isProcessing;

  /// Loads a chapter's highlights from the server, throttled to at most
  /// one real request per [chapterLoadThrottle] (armed only on success -
  /// a failed load leaves it unarmed so the next call retries
  /// immediately) and deduplicated against a concurrent in-flight load
  /// for the same chapter. Fire-and-forget (no `Future` returned, same
  /// as Kotlin's launch-a-coroutine shape) - observe [changes] for
  /// completion.
  void ensureLoaded({required int bibleId, required String chapterId, bool forceReload = false}) {
    final key = _chapterKey(bibleId, chapterId);
    if (!forceReload) {
      final last = _lastChapterFetch[key];
      if (last != null && DateTime.now().difference(last) < chapterLoadThrottle) return;
      if (_chapterLoadInFlight.containsKey(key)) return;
    }

    final inFlight = _chapterLoadInFlight[key];
    if (inFlight != null) {
      // forceReload while already loading - wait for the current load,
      // then do exactly one follow-up (matches Kotlin: doesn't stack
      // reloads if more forceReload calls arrive meanwhile).
      _chapterLoadInFlight[key] = inFlight.then((_) => _loadChapter(bibleId, chapterId, key));
      return;
    }
    _chapterLoadInFlight[key] = _loadChapter(bibleId, chapterId, key);
  }

  Future<void> _loadChapter(int bibleId, String chapterId, String key) async {
    final generationAtStart = _generation;
    final token = _accessToken();
    if (token == null) {
      _chapterLoadInFlight.remove(key);
      return;
    }
    try {
      final highlights = await _client.listHighlights(
        userAccessToken: token,
        bibleId: bibleId,
        passageId: chapterId,
      );
      if (generationAtStart != _generation) return; // dropped by a reset() mid-flight
      _highlightsByChapter[key] = {for (final h in highlights) h.passageId: h};
      for (final h in highlights) {
        _serverBackedPassageIds.add(_passageKey(h.bibleId, h.passageId));
      }
      _lastChapterFetch[key] = DateTime.now();
      _notify();
    } on YouVersionException {
      // Leave the throttle unarmed - the next call retries immediately.
    } finally {
      _chapterLoadInFlight.remove(key);
    }
  }

  /// Creates or re-colors a highlight (one write shape covers both - the
  /// server treats them the same way: "ensure a highlight of this color
  /// exists here"). Optimistic: applied to the local view immediately,
  /// synced afterward.
  void setHighlight({
    required int bibleId,
    required String chapterId,
    required String passageId,
    required String color,
  }) {
    final map = _highlightsByChapter.putIfAbsent(_chapterKey(bibleId, chapterId), () => {});
    map[passageId] = Highlight(bibleId: bibleId, passageId: passageId, color: color);
    _enqueue(bibleId: bibleId, chapterId: chapterId, passageId: passageId, color: color);
  }

  /// Removes a highlight. Optimistic, same reasoning as [setHighlight].
  void removeHighlight({required int bibleId, required String chapterId, required String passageId}) {
    _highlightsByChapter[_chapterKey(bibleId, chapterId)]?.remove(passageId);
    _enqueue(bibleId: bibleId, chapterId: chapterId, passageId: passageId, color: null);
  }

  void _enqueue({
    required int bibleId,
    required String chapterId,
    required String passageId,
    required String? color,
  }) {
    _queue.add(
      _PendingOperation(
        id: _nextOperationId++,
        bibleId: bibleId,
        chapterId: chapterId,
        passageId: passageId,
        color: color,
        generation: _generation,
      ),
    );
    _notify();
    _scheduleProcessing();
  }

  void _scheduleProcessing() {
    if (_isProcessing || _closed) return;
    _isProcessing = true;
    unawaited(_processQueue());
  }

  Future<void> _processQueue() async {
    while (!_closed) {
      if (_queue.isEmpty) {
        _isProcessing = false;
        return;
      }

      final generationAtStart = _generation;
      final batch = List<_PendingOperation>.of(_queue);
      _queue.clear();
      _notify();

      final failed = <_PendingOperation>[];
      final rejectedChapters = <(int, String)>{};
      var wasRejected = false;

      for (final op in batch) {
        if (wasRejected) {
          rejectedChapters.add((op.bibleId, op.chapterId));
          _failedOperationCount++;
          continue;
        }

        final token = _accessToken();
        if (token == null) {
          op.retryCount++;
          failed.add(op);
          continue;
        }

        try {
          await _send(op, token);
        } on YouVersionException catch (e) {
          if (e.reason == YouVersionErrorReason.notPermitted) {
            wasRejected = true;
            rejectedChapters.add((op.bibleId, op.chapterId));
            _failedOperationCount++;
          } else {
            op.retryCount++;
            failed.add(op);
          }
        } catch (_) {
          op.retryCount++;
          failed.add(op);
        }
      }

      if (wasRejected) {
        // A permission refusal is account-wide, not per-operation -
        // abandon everything else still queued too (anything enqueued
        // while this batch was in flight), not just the rest of this
        // batch.
        for (final leftover in _queue) {
          rejectedChapters.add((leftover.bibleId, leftover.chapterId));
          _failedOperationCount++;
        }
        _queue.clear();
        for (final (chapterBibleId, chapterId) in rejectedChapters) {
          ensureLoaded(bibleId: chapterBibleId, chapterId: chapterId, forceReload: true);
        }
        _notify();
        continue;
      }

      if (failed.isEmpty) {
        _notify();
        continue;
      }

      if (generationAtStart != _generation) {
        // A reset() happened mid-batch (e.g. sign-out) - drop the failed
        // retries instead of requeuing them under the new session.
        _notify();
        continue;
      }

      _queue.insertAll(0, failed);
      _notify();
      final maxRetry = failed.map((o) => o.retryCount).reduce((a, b) => a > b ? a : b);
      await Future<void>.delayed(_backoff(maxRetry));
    }
    _isProcessing = false;
  }

  Future<void> _send(_PendingOperation op, String token) async {
    final passageKey = _passageKey(op.bibleId, op.passageId);
    if (op.color != null) {
      if (_serverBackedPassageIds.contains(passageKey)) {
        await _client.updateHighlight(
          userAccessToken: token,
          bibleId: op.bibleId,
          passageId: op.passageId,
          color: op.color!,
        );
      } else {
        await _client.createHighlight(
          userAccessToken: token,
          bibleId: op.bibleId,
          passageId: op.passageId,
          color: op.color!,
        );
        _serverBackedPassageIds.add(passageKey);
      }
    } else {
      try {
        await _client.deleteHighlight(userAccessToken: token, bibleId: op.bibleId, passageId: op.passageId);
      } on YouVersionException catch (e) {
        // Already gone server-side (deleted from another device, or an
        // earlier attempt of this same operation actually succeeded
        // before a retry got triggered) - that IS the successful end
        // state for a delete, not a failure to retry forever. Confirmed
        // live: `deleteHighlight`'s `_reasonForWrite` maps a 404 to
        // `YouVersionErrorReason.cannotDownload` (nothing 404-specific
        // in the reason taxonomy), so this checks `statusCode` directly
        // rather than `reason`.
        if (e.statusCode != 404) rethrow;
      }
      _serverBackedPassageIds.remove(passageKey);
    }
  }

  /// Clears the queue, cache, and in-flight-load bookkeeping, and bumps
  /// an internal generation counter so any retry/load still in flight
  /// from before this call is dropped on completion instead of applied.
  /// Call explicitly on sign-out/account-switch - see the class doc
  /// comment for why this can't be automatic.
  void reset() {
    _generation++;
    _queue.clear();
    _highlightsByChapter.clear();
    _serverBackedPassageIds.clear();
    _lastChapterFetch.clear();
    _chapterLoadInFlight.clear();
    _failedOperationCount = 0;
    _notify();
  }

  void close() {
    _closed = true;
    _changesController.close();
  }
}
