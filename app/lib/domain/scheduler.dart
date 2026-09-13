import 'models.dart';

/// Every tunable of the spaced-repetition model lives here (baseline §3).
class SchedulerConfig {
  const SchedulerConfig({
    this.firstUnknown = const Duration(minutes: 10),
    this.unknownRestart = const Duration(days: 1),
    this.issuesGrowth = 2.5,
    this.issuesMin = const Duration(days: 1),
    this.maxInterval = const Duration(days: 180),
  });

  /// A word failed for the first time comes back within the same session.
  final Duration firstUnknown;

  /// A word failed again restarts from here.
  final Duration unknownRestart;

  /// "Had issues" multiplies the current interval by this.
  final double issuesGrowth;

  /// …but never schedules sooner than this.
  final Duration issuesMin;
  final Duration maxInterval;
}

/// Pure transition: previous progress (null = new word) + grade → next.
Progress applyGrade({
  required Progress? previous,
  required int wordId,
  required String lemma,
  required Grade grade,
  required DateTime now,
  SchedulerConfig config = const SchedulerConfig(),
}) {
  final prev = previous ??
      Progress(
        wordId: wordId,
        lemma: lemma,
        state: ProgressState.learning,
        interval: Duration.zero,
        dueAt: null,
        seenCount: 0,
        lapseCount: 0,
        retiredBy: null,
        updatedAt: now,
      );

  switch (grade) {
    case Grade.know:
      return prev.copyWith(
        state: ProgressState.retired,
        dueAt: () => null,
        retiredBy: () => RetiredBy.swipe,
        seenCount: prev.seenCount + 1,
        updatedAt: now,
      );
    case Grade.unknown:
      final interval = prev.interval == Duration.zero
          ? config.firstUnknown
          : config.unknownRestart;
      return prev.copyWith(
        state: ProgressState.learning,
        interval: interval,
        dueAt: () => now.add(interval),
        retiredBy: () => null,
        seenCount: prev.seenCount + 1,
        lapseCount: prev.lapseCount + 1,
        updatedAt: now,
      );
    case Grade.issues:
      var grown = Duration(
        milliseconds:
            (prev.interval.inMilliseconds * config.issuesGrowth).round(),
      );
      if (grown < config.issuesMin) grown = config.issuesMin;
      if (grown > config.maxInterval) grown = config.maxInterval;
      return prev.copyWith(
        state: ProgressState.learning,
        interval: grown,
        dueAt: () => now.add(grown),
        retiredBy: () => null,
        seenCount: prev.seenCount + 1,
        updatedAt: now,
      );
  }
}
