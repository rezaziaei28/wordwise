import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/settings.dart';
import '../../data/progress/progress_repository.dart';
import '../../domain/models.dart';
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
    await _fill();
    return _snapshot();
  }

  Future<ReviewState> _snapshot() async {
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
    );
  }

  /// Top the queue up to a page: due reviews first, then new words by rank.
  Future<void> _fill() async {
    if (_queue.length >= _prefetchAt) return;
    final dict = ref.read(dictionaryProvider);
    final settings = await ref.read(settingsProvider.future);
    final now = _now;

    final dueRows = await _repo.due(now, limit: _pageSize);
    final dueWords = {for (final w in dict.byIds(dueRows.map((p) => p.wordId))) w.id: w};
    final dueItems = [
      for (final p in dueRows)
        if (dueWords[p.wordId] != null && !_inQueue.contains(p.wordId)) QueueItem(word: dueWords[p.wordId]!, progress: p),
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
        if (!_inQueue.contains(w.id)) newItems.add(QueueItem(word: w, progress: null));
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
    for (final item in plan.items) {
      _queue.add(item);
      _inQueue.add(item.word.id);
    }
  }

  Future<void> swipe(Grade grade) async {
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
    _tickRelearn();
    await _fill();
    state = AsyncData(await _snapshot());
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

  Future<void> undo() async {
    final last = await _repo.lastSwipe();
    if (last == null) return;
    await _repo.revert(last);
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
  Future<void> continuePastCap() async {
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
