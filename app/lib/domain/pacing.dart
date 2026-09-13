import 'models.dart';

/// Streak-based acceleration (design/01 §3, D-010): after [streakLength]
/// consecutive "know" grades on fresh words, the next [skipSize] unseen
/// words are marked *skipped* instead of being shown. The jump grows while
/// streaks continue without a miss and resets on any other grade. Skipped
/// words are mixed back in once the learner's know-rate on fresh words
/// drops below [mixBelowKnowRate] — the frontier has been reached.
class PacingConfig {
  const PacingConfig({
    this.streakLength = 10,
    this.skipBase = 100,
    this.skipMax = 1000,
    this.mixWindow = 20,
    this.mixBelowKnowRate = 0.7,
    this.mixEvery = 4,
  });

  final int streakLength;
  final int skipBase;
  final int skipMax;

  /// How many recent fresh-word grades to look at.
  final int mixWindow;
  final double mixBelowKnowRate;

  /// One skipped word per this many new words when mixing.
  final int mixEvery;

  /// Size of the [nthRun]-th consecutive jump (1-based): 100, 200, 400, …
  int skipSize(int nthRun) {
    var size = skipBase;
    for (var i = 1; i < nthRun && size < skipMax; i++) {
      size *= 2;
    }
    return size > skipMax ? skipMax : size;
  }

  /// True once the learner misses often enough on fresh words.
  bool shouldMix(List<Grade> recentFreshGrades) {
    if (recentFreshGrades.length < mixWindow) return false;
    final window = recentFreshGrades.take(mixWindow);
    final known = window.where((g) => g == Grade.know).length;
    return known / mixWindow < mixBelowKnowRate;
  }
}
