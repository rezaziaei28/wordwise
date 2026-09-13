import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/grade_style.dart';
import '../../core/providers.dart';
import '../../core/word_providers.dart';
import '../../domain/models.dart';
import '../review/review_controller.dart';

class StatsData {
  const StatsData({
    required this.today,
    required this.retired,
    required this.learning,
    required this.dueNow,
    required this.highestBand,
    required this.retiredPerBand,
    required this.totalWords,
    required this.knownFraction,
    required this.textCoverage,
    required this.skipped,
  });

  final Map<Grade, int> today;
  final int retired;
  final int learning;
  final int dueNow;
  final int highestBand;

  /// index 0 = band 1
  final List<int> retiredPerBand;
  final int totalWords;

  /// retired / total words.
  final double knownFraction;

  /// Frequency-weighted share of running text made of retired words
  /// (relative to the 40K list; knowing the top 5K already covers ~93 %).
  final double textCoverage;

  /// Jumped over by the streak rule, not yet verified.
  final int skipped;
}

final statsProvider = FutureProvider<StatsData>((ref) async {
  ref.watch(progressVersionProvider);
  ref.watch(reviewControllerProvider); // refresh after swipes
  final repo = ref.watch(progressRepositoryProvider);
  final now = DateTime.now();
  final swipes = await repo.swipesSince(DateTime(now.year, now.month, now.day));
  final today = {for (final g in Grade.values) g: swipes.where((e) => e.grade == g.name).length};
  final retiredIds = await repo.retiredIds();
  final total = ref.watch(dictionaryProvider).count;
  final bands = (total + 999) ~/ 1000;
  final perBand = List<int>.filled(bands, 0);
  for (final id in retiredIds) {
    final b = (id - 1) ~/ 1000;
    if (b < bands) perBand[b]++;
  }
  final weights = ref.watch(dictionaryProvider).frequencyWeights();
  final totalWeight = weights.values.fold(0.0, (a, b) => a + b);
  final knownWeight = retiredIds.fold(0.0, (a, id) => a + (weights[id] ?? 0));
  final learningIds = await repo.idsByState(ProgressState.learning, offset: 0, limit: 1 << 20);
  final highest = [...retiredIds, ...learningIds].fold<int>(0, (m, id) => id > m ? id : m);
  return StatsData(
    today: today,
    retired: retiredIds.length,
    learning: learningIds.length,
    dueNow: await repo.dueCount(now),
    highestBand: highest == 0 ? 0 : (highest - 1) ~/ 1000 + 1,
    retiredPerBand: perBand,
    totalWords: total,
    knownFraction: total == 0 ? 0 : retiredIds.length / total,
    textCoverage: totalWeight == 0 ? 0 : knownWeight / totalWeight,
    skipped: await repo.countByState(ProgressState.skipped),
  );
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(statsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _KnownHero(stats: s),
            const SizedBox(height: 24),
            Text('Today', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final g in [Grade.know, Grade.issues, Grade.unknown])
                  Expanded(child: _Tile(label: g.label, value: '${s.today[g]}', color: g.color)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Totals', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _Tile(label: 'retired', value: '${s.retired}')),
                Expanded(child: _Tile(label: 'learning', value: '${s.learning}')),
                Expanded(child: _Tile(label: 'due now', value: '${s.dueNow}')),
              ],
            ),
            const SizedBox(height: 8),
            Text('Highest band touched: ${s.highestBand} of ${s.retiredPerBand.length}'
                '${s.skipped > 0 ? ' · ${s.skipped} words skipped ahead, to be checked later' : ''}',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            Text('Retired per band (1,000 words each)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (var i = 0; i < s.retiredPerBand.length; i++)
                  Tooltip(
                    message: 'Band ${i + 1}: ${s.retiredPerBand[i]} retired',
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Color.lerp(theme.colorScheme.surfaceContainerHighest, const Color(0xFF2E9E5B), s.retiredPerBand[i] / 1000),
                      ),
                      child: Text('${i + 1}', style: theme.textTheme.labelSmall),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "You know 12.5 % of the words" plus the share of everyday text that is.
class _KnownHero extends StatelessWidget {
  const _KnownHero({required this.stats});
  final StatsData stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pct = stats.knownFraction * 100;
    final pctText = pct >= 10 ? pct.toStringAsFixed(0) : pct.toStringAsFixed(1);
    return Card(
      color: scheme.primaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$pctText %', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('of ${_thousands(stats.totalWords)} words known\n${_thousands(stats.retired)} retired',
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: stats.knownFraction, minHeight: 8, backgroundColor: scheme.onPrimaryContainer.withValues(alpha: 0.12)),
            ),
            const SizedBox(height: 12),
            Text(
              '≈ ${(stats.textCoverage * 100).toStringAsFixed(0)} % of everyday English text is made of words you know',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }

  static String _thousands(int n) => n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: color)),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
