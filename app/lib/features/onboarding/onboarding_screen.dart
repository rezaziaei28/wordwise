import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/grade_style.dart';
import '../../core/providers.dart';
import '../../core/settings.dart';
import '../../core/word_providers.dart';
import '../../domain/models.dart';
import '../review/review_controller.dart';
import '../review/widgets/swipe_stack.dart';
import '../review/widgets/word_card.dart';

const _bands = 5;
const _perBand = 8;

/// First launch: explain the three swipes, then calibrate (MVP §2.3).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0; // 0 intro, 1 calibrate, 2 summary
  late final List<Word> _samples;
  int _index = 0;
  final Map<int, int> _knownPerBand = {};
  final SwipeStackKey _stack = SwipeStackKey();

  @override
  void initState() {
    super.initState();
    final dict = ref.read(dictionaryProvider);
    _samples = [for (var b = 1; b <= _bands; b++) ...dict.sampleBand(b, _perBand)];
  }

  /// Highest band such that every band up to it was fully known.
  int get _fullyKnownUpTo {
    var upTo = 0;
    for (var b = 1; b <= _bands; b++) {
      if ((_knownPerBand[b] ?? 0) == _perBand) {
        upTo = b;
      } else {
        break;
      }
    }
    return upTo;
  }

  Future<void> _grade(Grade g) async {
    final w = _samples[_index];
    if (g == Grade.know) _knownPerBand[w.band] = (_knownPerBand[w.band] ?? 0) + 1;
    setState(() {
      _index++;
      if (_index >= _samples.length) _step = 2;
    });
  }

  Future<void> _finish({required bool bulk}) async {
    if (bulk && _fullyKnownUpTo > 0) {
      final dict = ref.read(dictionaryProvider);
      final words = dict.page(offset: 0, limit: _fullyKnownUpTo * 1000);
      await ref.read(progressRepositoryProvider).bulkRetire(words, DateTime.now());
      ref.read(progressVersionProvider.notifier).bump();
    }
    await ref.read(settingsProvider.notifier).setOnboarded();
    await ref.read(reviewControllerProvider.notifier).refresh();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: switch (_step) {
          0 => _Intro(onNext: () => setState(() => _step = 1), onSkip: () => _finish(bulk: false)),
          1 => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Quick check', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text('${_index + 1} of ${_samples.length} · be honest, this only sets your starting point',
                          style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _index / _samples.length),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SwipeStack(
                      key: _stack,
                      itemKey: _samples[_index].id,
                      current: WordCard(key: ValueKey(_samples[_index].id), word: _samples[_index]),
                      next: _index + 1 < _samples.length ? WordCard(key: ValueKey(_samples[_index + 1].id), word: _samples[_index + 1], interactive: false) : null,
                      onSwipe: _grade,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      for (final g in [Grade.unknown, Grade.issues, Grade.know]) ...[
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () => _stack.commit(g),
                            style: FilledButton.styleFrom(foregroundColor: g.color),
                            child: Text(g.label),
                          ),
                        ),
                        if (g != Grade.know) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          _ => _Summary(upTo: _fullyKnownUpTo, onFinish: _finish),
        },
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onNext, required this.onSkip});
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text('Wordwise', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('The 40,000 words a fluent reader knows — meaning and pronunciation — one card at a time, most common first.',
              style: theme.textTheme.bodyLarge),
          const SizedBox(height: 28),
          for (final g in [Grade.know, Grade.issues, Grade.unknown])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: g.color.withValues(alpha: 0.15), child: Icon(g.icon, color: g.color)),
              title: Text('${_dir(g)} — ${g.label}'),
              subtitle: Text(g.hint),
            ),
          const SizedBox(height: 8),
          Text('Tap a card to see its meaning and hear it. You grade yourself; nobody is checking.', style: theme.textTheme.bodyMedium),
          const Spacer(),
          Row(
            children: [
              TextButton(onPressed: onSkip, child: const Text('Skip check')),
              const Spacer(),
              FilledButton(onPressed: onNext, child: const Text('Start quick check')),
            ],
          ),
        ],
      ),
    );
  }

  static String _dir(Grade g) => switch (g) { Grade.know => 'Swipe right', Grade.issues => 'Swipe down', Grade.unknown => 'Swipe left' };
}

class _Summary extends StatelessWidget {
  const _Summary({required this.upTo, required this.onFinish});
  final int upTo;
  final Future<void> Function({required bool bulk}) onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(upTo == 0 ? 'Starting from the top' : 'You knew all of bands 1–$upTo', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            upTo == 0
                ? 'You will start at word #1. Swiping "Know it" is fast — the first few hundred will fly by.'
                : 'Retire words 1–${upTo * 1000} now and start at #${upTo * 1000 + 1}? You can undo this in Settings, and any word can be un-retired from the list.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (upTo > 0) ...[
            FilledButton(onPressed: () => onFinish(bulk: true), child: Text('Retire words 1–${upTo * 1000}')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => onFinish(bulk: false), child: const Text('No, start from #1')),
          ] else
            FilledButton(onPressed: () => onFinish(bulk: false), child: const Text('Start')),
        ],
      ),
    );
  }
}
