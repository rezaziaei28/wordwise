import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/settings.dart';
import '../../data/progress/progress_repository.dart';
import '../../domain/models.dart';
import '../../domain/pacing.dart';
import '../../domain/queue_policy.dart';
import '../../domain/scheduler.dart';

/// What the review screen renders.
class ReviewState {
  const ReviewState({
    required this.current,
    required this.next,
    required this.doneToday,
    required this.newToday,
    required this.dueNow,
    required this.newCapReached,
    required this.canUndo,
    required this.exhausted,
    this.streak = 0,
    this.lastSkip,
  });

  final QueueItem? current;
  final QueueItem? next;
  final int doneToday;
  final int newToday;
  final int dueNow;

  /// Today's new-word allowance is spent and nothing is due.
  final bool newCapReached;
  final bool canUndo;

  /// Every word in the dictionary has been seen or retired.
  final bool exhausted;

  /// Consecutive "know" grades on fresh words, for the streak indicator.
  final int streak;

  /// Set right after a jump: (words skipped, rank now at the front). The UI
  /// shows it once; it is cleared on the next state.
  final (int, int)? lastSkip;
}

/// Owns the in-memory queue; persists every swipe through the repository.
///
/// A word graded *unknown* for the first time is re-inserted into the
/// in-memory queue ~20 cards later so it comes back within the session even
/// if the wall-clock due time has not passed yet (A8).
class ReviewController extends AsyncNotifier<ReviewState> {
  static const _pageSize = 20;
  static const _prefetchAt = 5;
  static const _relearnAfterCards = 20;

  final Queue<QueueItem> _queue = Queue();
  final List<(int cardsLeft, QueueItem item)> _relearn = [];
  final Set<int> _inQueue = {};
  bool _ignoreCap = false;
  int _nextNewRank = 0;

  /// Queue mutations run one at a time. Without this, two swipes in flight
  /// together (a double-tapped grade button) each top the queue up from the
  /// same snapshot and enqueue the same words twice, so a word comes back
  /// after it was already retired.
  Future<void> _lock = Future.value();

  /// A fill already in flight; a second caller joins it instead of starting
  /// a second scan.
  Future<void>? _filling;

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  // Streak rule (domain/pacing.dart): consecutive knows on fresh words, and
  // how many jumps happened without a miss in between (grows the jump).
  int _streak = 0;
  int _runs = 0;
  bool _mixing = false;

  ProgressRepository get _repo => ref.read(progressRepositoryProvider);
  DateTime get _now => ref.read(clockProvider)();
  DateTime get _dayStart {
    final n = _now;
    return DateTime(n.year, n.month, n.day);
  }

  @override
  Future<ReviewState> build() async {
    _queue.clear();
    _relearn.clear();
    _inQueue.clear();
    _nextNewRank = int.tryParse(await _repo.setting(SettingKeys.nextNewRank) ?? '') ?? 0;
    await _restoreStreak();
    await _fill();
    return _snapshot();
  }

  PacingConfig get _pacing => ref.read(pacingConfigProvider);

  /// A swipe on a word never graded before: new, or skipped by the rule.
  static bool _isFresh(LogEntry e) => e.before == null || e.before!.isSkipped;

  /// Rebuild the streak from the log so a restart does not lose it.
  Future<void> _restoreStreak() async {
    _streak = 0;
    for (final e in await _repo.recentSwipes(limit: _pacing.streakLength)) {
      if (e.grade == Grade.know.name && _isFresh(e)) {
        _streak++;
      } else {
        break;
      }
    }
  }

  Future<List<Grade>> _recentFreshGrades() async => [
        for (final e in await _repo.recentSwipes(limit: _pacing.mixWindow * 3))
          if (_isFresh(e)) Grade.values.byName(e.grade),
      ].take(_pacing.mixWindow).toList();

  /// Mark the next [n] unseen words as skipped and drop them from the queue.
  Future<int> _skipAhead(int n) async {
    final dict = ref.read(dictionaryProvider);
    final picked = <Word>[];
    var scan = _nextNewRank;
    while (picked.length < n) {
      final candidates = dict.afterRank(scan, limit: 200);
      if (candidates.isEmpty) break;
      final known = await _repo.getMany(candidates.map((w) => w.id));
      picked.addAll(candidates.where((w) => !known.containsKey(w.id)).take(n - picked.length));
      scan = candidates.last.rank;
    }
    final skipped = await _repo.skipWords(picked, _now);
    final ids = picked.map((w) => w.id).toSet();
    _queue.removeWhere((q) => ids.contains(q.word.id));
    _inQueue.removeAll(ids);
    return skipped;
  }

  Future<ReviewState> _snapshot({(int, int)? lastSkip}) async {
    final today = await _repo.swipesSince(_dayStart);
    final settings = await ref.read(settingsProvider.future);
    final dueNow = await _repo.dueCount(_now);
    final newToday = today.where((e) => e.before == null).length;
    return ReviewState(
      current: _queue.isEmpty ? null : _queue.first,
      next: _queue.length < 2 ? null : _queue.elementAt(1),
      doneToday: today.length,
      newToday: newToday,
      dueNow: dueNow,
      newCapReached: _queue.isEmpty && !_ignoreCap && newToday >= settings.newPerDay && _nextNewRank < ref.read(dictionaryProvider).count,
      canUndo: await _repo.lastSwipe() != null,
      exhausted: _queue.isEmpty && _nextNewRank >= ref.read(dictionaryProvider).count,
      streak: _streak,
      lastSkip: lastSkip,
    );
  }

  /// Top the queue up to a page: due reviews first, then new words by rank.
  Future<void> _fill() => _filling ??= _fillOnce().whenComplete(() => _filling = null);

  Future<void> _fillOnce() async {
    if (_queue.length >= _prefetchAt) return;
    final dict = ref.read(dictionaryProvider);
    final settings = await ref.read(settingsProvider.future);
    final now = _now;

    final dueRows = await _repo.due(now, limit: _pageSize);
    final dueWords = {for (final w in dict.byIds(dueRows.map((p) => p.wordId))) w.id: w};
    final dueItems = [
      for (final p in dueRows)
        if (dueWords[p.wordId] != null && _inQueue.add(p.wordId)) QueueItem(word: dueWords[p.wordId]!, progress: p),
    ];

    // `_nextNewRank` is the settled prefix: every rank ≤ it has a progress
    // row. It only advances over contiguous known words, never past a word
    // that is merely queued, so nothing is skipped if the app is closed.
    final newItems = <QueueItem>[];
    var cursor = _nextNewRank;
    var scan = _nextNewRank;
    var contiguous = true;
    while (newItems.length < _pageSize) {
      final candidates = dict.afterRank(scan, limit: 100);
      if (candidates.isEmpty) break;
      final known = await _repo.getMany(candidates.map((w) => w.id));
      for (final w in candidates) {
        if (known.containsKey(w.id)) {
          if (contiguous) cursor = w.rank;
          continue;
        }
        contiguous = false;
        if (_inQueue.add(w.id)) newItems.add(QueueItem(word: w, progress: null));
        if (newItems.length >= _pageSize) break;
      }
      scan = candidates.last.rank;
    }
    if (cursor != _nextNewRank) {
      _nextNewRank = cursor;
      await _repo.setSetting(SettingKeys.nextNewRank, '$cursor');
    }

    final newToday = (await _repo.swipesSince(_dayStart)).where((e) => e.before == null).length;
    final queuedNew = _queue.where((q) => q.isNew).length; // already counts against today
    final plan = planQueue(
      dueReviews: dueItems,
      newWords: newItems,
      newPerDay: settings.newPerDay,
      newIntroducedToday: newToday + queuedNew,
      ignoreCap: _ignoreCap,
    );

    // Once the frontier is reached, interleave words skipped earlier —
    // easiest first — one per `mixEvery` new words (or alone when there is
    // nothing new left).
    _mixing = _mixing || _pacing.shouldMix(await _recentFreshGrades());
    final picked = plan.items.where((i) => i.isNew).length;
    final skippedWanted = _mixing ? (picked == 0 ? _pageSize : (picked / _pacing.mixEvery).ceil()) : 0;
    final skippedItems = <QueueItem>[];
    if (skippedWanted > 0) {
      final ids = await _repo.idsByState(ProgressState.skipped, offset: 0, limit: skippedWanted * 2);
      final rows = await _repo.getMany(ids);
      for (final w in dict.byIds(ids)) {
        if (rows[w.id] == null || !_inQueue.add(w.id)) continue;
        skippedItems.add(QueueItem(word: w, progress: rows[w.id]));
        if (skippedItems.length >= skippedWanted) break;
      }
    }

    var s = 0;
    for (var i = 0; i < plan.items.length; i++) {
      final item = plan.items[i];
      _queue.add(item);
      _inQueue.add(item.word.id);
      if (item.isNew && s < skippedItems.length && (i + 1) % _pacing.mixEvery == 0) {
        _queue.add(skippedItems[s]);
        _inQueue.add(skippedItems[s++].word.id);
      }
    }
    for (; s < skippedItems.length; s++) {
      _queue.add(skippedItems[s]);
      _inQueue.add(skippedItems[s].word.id);
    }

    // `_inQueue` mirrors the queue. Candidates reserved above but dropped by
    // the daily cap are released here, so they are offered again next fill.
    _inQueue
      ..clear()
      ..addAll(_queue.map((q) => q.word.id));
  }

  Future<void> swipe(Grade grade) => _serial(() => _swipe(grade));

  Future<void> _swipe(Grade grade) async {
    final item = _queue.isEmpty ? null : _queue.removeFirst();
    if (item == null) return;
    _inQueue.remove(item.word.id);
    _relearn.removeWhere((r) => r.$2.word.id == item.word.id);

    final now = _now;
    final after = applyGrade(
      previous: item.progress,
      wordId: item.word.id,
      lemma: item.word.lemma,
      grade: grade,
      now: now,
      config: ref.read(schedulerConfigProvider),
    );
    await _repo.recordSwipe(before: item.progress, after: after, grade: grade);

    // Session-level relearn: bring a freshly failed word back soon.
    if (grade == Grade.unknown && after.interval == ref.read(schedulerConfigProvider).firstUnknown) {
      _relearn.add((_relearnAfterCards, QueueItem(word: item.word, progress: after)));
    }

    // Streak rule: skip ahead after N knows in a row on fresh words.
    (int, int)? lastSkip;
    final fresh = item.isNew || (item.progress?.isSkipped ?? false);
    if (grade == Grade.know && fresh) {
      _streak++;
    } else {
      _streak = 0;
      _runs = 0;
    }
    final settings = await ref.read(settingsProvider.future);
    if (settings.skipAhead && _streak >= _pacing.streakLength && !_mixing) {
      _streak = 0;
      _runs++;
      final n = await _skipAhead(_pacing.skipSize(_runs));
      if (n > 0) {
        await _fill();
        final front = _queue.where((q) => q.isNew).firstOrNull?.word.rank;
        if (front != null) lastSkip = (n, front);
      }
    }
    _tickRelearn();
    await _fill();
    state = AsyncData(await _snapshot(lastSkip: lastSkip));
  }

  void _tickRelearn() {
    for (var i = 0; i < _relearn.length; i++) {
      final (left, item) = _relearn[i];
      _relearn[i] = (left - 1, item);
    }
    final ready = _relearn.where((r) => r.$1 <= 0 || _queue.isEmpty).toList();
    for (final r in ready) {
      _relearn.remove(r);
      if (!_inQueue.contains(r.$2.word.id)) {
        _queue.addFirst(r.$2);
        _inQueue.add(r.$2.word.id);
      }
    }
  }

  Future<void> undo() => _serial(_undo);

  Future<void> _undo() async {
    final last = await _repo.lastSwipe();
    if (last == null) return;
    await _repo.revert(last);
    await _restoreStreak();
    _relearn.removeWhere((r) => r.$2.word.id == last.wordId);
    final word = ref.read(dictionaryProvider).byId(last.wordId);
    if (word != null) {
      if (_inQueue.contains(word.id)) {
        _queue.removeWhere((q) => q.word.id == word.id);
      }
      _queue.addFirst(QueueItem(word: word, progress: last.before));
      _inQueue.add(word.id);
    }
    state = AsyncData(await _snapshot());
  }

  /// "Keep going" past the daily cap (A9).
  Future<void> continuePastCap() => _serial(_continuePastCap);

  Future<void> _continuePastCap() async {
    _ignoreCap = true;
    await _fill();
    state = AsyncData(await _snapshot());
  }

  /// Re-read after external changes (word list retire, calibration, import).
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final reviewControllerProvider = AsyncNotifierProvider<ReviewController, ReviewState>(ReviewController.new);
