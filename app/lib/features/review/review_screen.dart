import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/grade_style.dart';
import '../../domain/models.dart';
import 'review_controller.dart';
import 'widgets/swipe_stack.dart';
import 'widgets/word_card.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final SwipeStackKey _stack = SwipeStackKey();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewControllerProvider);
    final ctrl = ref.read(reviewControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wordwise'),
        actions: [
          IconButton(
            tooltip: 'Undo last swipe',
            onPressed: state.value?.canUndo == true ? ctrl.undo : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(tooltip: 'Words', onPressed: () => context.push('/words'), icon: const Icon(Icons.list_alt_rounded)),
          IconButton(tooltip: 'Stats', onPressed: () => context.push('/stats'), icon: const Icon(Icons.insights_rounded)),
          IconButton(tooltip: 'Settings', onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings_rounded)),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong:\n$e', textAlign: TextAlign.center)),
        data: (s) => Column(
          children: [
            _Header(state: s),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: s.current == null
                    ? _Empty(state: s, onContinue: ctrl.continuePastCap)
                    : SwipeStack(
                        key: _stack,
                        itemKey: s.current!.word.id,
                        current: WordCard(
                          key: ValueKey('card-${s.current!.word.id}'),
                          word: s.current!.word,
                          onLongPress: () => context.push('/words/${s.current!.word.id}'),
                        ),
                        next: s.next == null ? null : WordCard(key: ValueKey('card-${s.next!.word.id}'), word: s.next!.word, interactive: false),
                        onSwipe: ctrl.swipe,
                      ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    for (final g in [Grade.unknown, Grade.issues, Grade.know]) ...[
                      Expanded(
                        child: _GradeButton(grade: g, enabled: s.current != null, onPressed: () => _stack.commit(g)),
                      ),
                      if (g != Grade.know) const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});
  final ReviewState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget stat(String label, int n) => Column(
          children: [
            Text('$n', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          stat('today', state.doneToday),
          stat('new today', state.newToday),
          stat('due', state.dueNow),
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({required this.grade, required this.enabled, required this.onPressed});
  final Grade grade;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${grade.label}: ${grade.hint}',
      child: FilledButton.tonal(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          foregroundColor: grade.color,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(grade.icon),
            const SizedBox(height: 2),
            Text(grade.label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.state, required this.onContinue});
  final ReviewState state;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, body, action) = state.exhausted
        ? ('All 40,000 words seen', 'Every word is either retired or scheduled. Come back when reviews are due.', null)
        : state.newCapReached
            ? ('Daily goal reached', "You've met today's new-word goal and nothing is due. Keep going anyway?", 'Keep going')
            : ('Nothing to review', 'Come back later for due words.', null);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.celebration_rounded, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(body, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onContinue, child: Text(action)),
          ],
        ],
      ),
    );
  }
}
