import 'models.dart';

/// One card in the review queue.
class QueueItem {
  const QueueItem({required this.word, required this.progress});

  final Word word;

  /// Null for a new word.
  final Progress? progress;

  bool get isNew => progress == null;
}

/// What the review screen should show next (tech §5.2).
class QueuePlan {
  const QueuePlan({required this.items, required this.newCapReached});

  final List<QueueItem> items;

  /// True when new words were withheld because today's allowance is spent.
  final bool newCapReached;

  bool get isEmpty => items.isEmpty;
}

/// Reviews first (already ordered by due time), then new words by rank, up
/// to the remaining daily allowance. The cap is soft: pass
/// `ignoreCap: true` to let the learner keep going.
QueuePlan planQueue({
  required List<QueueItem> dueReviews,
  required List<QueueItem> newWords,
  required int newPerDay,
  required int newIntroducedToday,
  bool ignoreCap = false,
}) {
  final allowance = ignoreCap
      ? newWords.length
      : (newPerDay - newIntroducedToday).clamp(0, newWords.length);
  final picked = newWords.take(allowance).toList();
  return QueuePlan(
    items: [...dueReviews, ...picked],
    newCapReached: !ignoreCap && picked.length < newWords.length,
  );
}
