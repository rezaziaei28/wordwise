import 'package:flutter_test/flutter_test.dart';
import 'package:wordwise/domain/models.dart';
import 'package:wordwise/domain/queue_policy.dart';

Word w(int id) => Word(
      id: id,
      lemma: 'w$id',
      band: 1,
      zipf: 5,
      ipa: null,
      isProper: false,
      isAbbrev: false,
      pos: const ['noun'],
    );

QueueItem fresh(int id) => QueueItem(word: w(id), progress: null);

QueueItem due(int id) => QueueItem(
      word: w(id),
      progress: Progress(
        wordId: id,
        lemma: 'w$id',
        state: ProgressState.learning,
        interval: const Duration(days: 1),
        dueAt: DateTime(2026),
        seenCount: 1,
        lapseCount: 0,
        retiredBy: null,
        updatedAt: DateTime(2026),
      ),
    );

void main() {
  test('reviews come before new words', () {
    final plan = planQueue(
      dueReviews: [due(9), due(8)],
      newWords: [fresh(1), fresh(2)],
      newPerDay: 50,
      newIntroducedToday: 0,
    );
    expect(plan.items.map((i) => i.word.id), [9, 8, 1, 2]);
    expect(plan.newCapReached, isFalse);
  });

  test('daily cap limits new words', () {
    final plan = planQueue(
      dueReviews: const [],
      newWords: [fresh(1), fresh(2), fresh(3)],
      newPerDay: 10,
      newIntroducedToday: 8,
    );
    expect(plan.items.length, 2);
    expect(plan.newCapReached, isTrue);
  });

  test('cap spent: only reviews, flag set', () {
    final plan = planQueue(
      dueReviews: [due(9)],
      newWords: [fresh(1)],
      newPerDay: 10,
      newIntroducedToday: 10,
    );
    expect(plan.items.map((i) => i.word.id), [9]);
    expect(plan.newCapReached, isTrue);
  });

  test('ignoreCap lets the learner keep going', () {
    final plan = planQueue(
      dueReviews: const [],
      newWords: [fresh(1), fresh(2)],
      newPerDay: 10,
      newIntroducedToday: 10,
      ignoreCap: true,
    );
    expect(plan.items.length, 2);
    expect(plan.newCapReached, isFalse);
  });
}
