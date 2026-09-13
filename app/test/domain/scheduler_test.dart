import 'package:flutter_test/flutter_test.dart';
import 'package:wordwise/domain/models.dart';
import 'package:wordwise/domain/scheduler.dart';

void main() {
  final now = DateTime(2026, 9, 12, 12);
  const cfg = SchedulerConfig();

  Progress grade(Progress? prev, Grade g, {DateTime? at}) => applyGrade(
        previous: prev,
        wordId: 42,
        lemma: 'ubiquitous',
        grade: g,
        now: at ?? now,
        config: cfg,
      );

  group('know', () {
    test('retires a new word', () {
      final p = grade(null, Grade.know);
      expect(p.state, ProgressState.retired);
      expect(p.dueAt, isNull);
      expect(p.retiredBy, RetiredBy.swipe);
      expect(p.seenCount, 1);
    });

    test('retires a learning word regardless of history', () {
      final learning = grade(grade(null, Grade.unknown), Grade.unknown);
      final p = grade(learning, Grade.know);
      expect(p.isRetired, isTrue);
      expect(p.lapseCount, 2, reason: 'history is kept');
    });
  });

  group('unknown', () {
    test('first time: due within the session', () {
      final p = grade(null, Grade.unknown);
      expect(p.interval, cfg.firstUnknown);
      expect(p.dueAt, now.add(cfg.firstUnknown));
      expect(p.lapseCount, 1);
      expect(p.isDue(now), isFalse);
      expect(p.isDue(now.add(const Duration(minutes: 11))), isTrue);
    });

    test('again: restarts at one day', () {
      final p = grade(grade(null, Grade.unknown), Grade.unknown);
      expect(p.interval, cfg.unknownRestart);
      expect(p.lapseCount, 2);
    });

    test('after a long interval: resets to one day', () {
      var p = grade(null, Grade.issues);
      for (var i = 0; i < 4; i++) {
        p = grade(p, Grade.issues);
      }
      expect(p.interval, greaterThan(const Duration(days: 30)));
      p = grade(p, Grade.unknown);
      expect(p.interval, cfg.unknownRestart);
    });

    test('un-retires a retired word', () {
      final p = grade(grade(null, Grade.know), Grade.unknown);
      expect(p.state, ProgressState.learning);
      expect(p.retiredBy, isNull);
    });
  });

  group('issues', () {
    test('new word: minimum one day', () {
      final p = grade(null, Grade.issues);
      expect(p.interval, cfg.issuesMin);
      expect(p.dueAt, now.add(cfg.issuesMin));
    });

    test('grows by the factor', () {
      final p1 = grade(null, Grade.issues);
      final p2 = grade(p1, Grade.issues);
      final p3 = grade(p2, Grade.issues);
      expect(p2.interval, const Duration(days: 1) * 2.5);
      expect(p3.interval, const Duration(days: 1) * 2.5 * 2.5);
    });

    test('after a 10-minute lapse still waits at least a day', () {
      final p = grade(grade(null, Grade.unknown), Grade.issues);
      expect(p.interval, cfg.issuesMin);
    });

    test('is capped', () {
      var p = grade(null, Grade.issues);
      for (var i = 0; i < 20; i++) {
        p = grade(p, Grade.issues);
      }
      expect(p.interval, cfg.maxInterval);
    });
  });

  test('json round-trip', () {
    final p = grade(grade(null, Grade.unknown), Grade.issues);
    expect(Progress.fromJson(p.toJson()).toJson(), p.toJson());
  });
}
