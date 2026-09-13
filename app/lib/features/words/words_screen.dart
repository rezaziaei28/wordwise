import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/word_providers.dart';
import '../../domain/models.dart';

enum WordFilter { all, learning, retired }

const _pageSize = 100;

/// A page of the word list under the active filter, joined with progress.
final wordPageProvider = FutureProvider.family<List<(Word, Progress?)>, (WordFilter, int)>((ref, arg) async {
  ref.watch(progressVersionProvider);
  final (filter, page) = arg;
  final dict = ref.watch(dictionaryProvider);
  final repo = ref.watch(progressRepositoryProvider);
  final List<Word> words;
  switch (filter) {
    case WordFilter.all:
      words = dict.page(offset: page * _pageSize, limit: _pageSize);
    case WordFilter.learning:
      words = dict.byIds(await repo.idsByState(ProgressState.learning, offset: page * _pageSize, limit: _pageSize));
    case WordFilter.retired:
      words = dict.byIds(await repo.idsByState(ProgressState.retired, offset: page * _pageSize, limit: _pageSize));
  }
  final progress = await repo.getMany(words.map((w) => w.id));
  return [for (final w in words) (w, progress[w.id])];
});

final wordCountProvider = FutureProvider.family<int, WordFilter>((ref, filter) async {
  ref.watch(progressVersionProvider);
  return switch (filter) {
    WordFilter.all => ref.watch(dictionaryProvider).count,
    WordFilter.learning => ref.watch(progressRepositoryProvider).countByState(ProgressState.learning),
    WordFilter.retired => ref.watch(progressRepositoryProvider).countByState(ProgressState.retired),
  };
});

final wordSearchProvider = FutureProvider.family<List<(Word, Progress?)>, String>((ref, q) async {
  ref.watch(progressVersionProvider);
  final words = ref.watch(dictionaryProvider).search(q);
  final progress = await ref.watch(progressRepositoryProvider).getMany(words.map((w) => w.id));
  return [for (final w in words) (w, progress[w.id])];
});

class WordsScreen extends ConsumerStatefulWidget {
  const WordsScreen({super.key});

  @override
  ConsumerState<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends ConsumerState<WordsScreen> {
  WordFilter _filter = WordFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(hintText: 'Search words and forms', border: InputBorder.none),
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
      ),
      body: Column(
        children: [
          if (_query.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final f in WordFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(label: Text(f.name), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
                    ),
                  const Spacer(),
                  Consumer(builder: (context, ref, _) {
                    final n = ref.watch(wordCountProvider(_filter)).value;
                    return Text(n == null ? '' : '$n words', style: Theme.of(context).textTheme.labelMedium);
                  }),
                ],
              ),
            ),
          Expanded(child: _query.isEmpty ? _PagedList(filter: _filter) : _SearchList(query: _query)),
        ],
      ),
    );
  }
}

class _PagedList extends ConsumerWidget {
  const _PagedList({required this.filter});
  final WordFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(wordCountProvider(filter)).value ?? 0;
    if (count == 0) return const Center(child: Text('Nothing here yet'));
    return ListView.builder(
      itemCount: count,
      itemExtent: 56,
      itemBuilder: (context, i) {
        final page = ref.watch(wordPageProvider((filter, i ~/ _pageSize)));
        final row = page.value?.elementAtOrNull(i % _pageSize);
        if (row == null) return const SizedBox.shrink();
        return WordRow(word: row.$1, progress: row.$2);
      },
    );
  }
}

class _SearchList extends ConsumerWidget {
  const _SearchList({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(wordSearchProvider(query)).value ?? const [];
    if (rows.isEmpty) return const Center(child: Text('No matches'));
    return ListView.builder(
      itemCount: rows.length,
      itemExtent: 56,
      itemBuilder: (context, i) => WordRow(word: rows[i].$1, progress: rows[i].$2),
    );
  }
}

class WordRow extends StatelessWidget {
  const WordRow({super.key, required this.word, required this.progress});
  final Word word;
  final Progress? progress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ProgressIcon(progress: progress),
      title: Text(word.lemma),
      subtitle: Text('#${word.rank} · band ${word.band}${word.isProper ? ' · name' : ''}'),
      trailing: word.ipa == null ? null : Text(word.ipa!, style: Theme.of(context).textTheme.bodySmall),
      onTap: () => context.push('/words/${word.id}'),
    );
  }
}

class ProgressIcon extends StatelessWidget {
  const ProgressIcon({super.key, required this.progress});
  final Progress? progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = progress;
    if (p == null) return Icon(Icons.circle_outlined, color: scheme.outlineVariant);
    if (p.isRetired) return const Icon(Icons.check_circle_rounded, color: Color(0xFF2E9E5B));
    if (p.isDue(DateTime.now())) return const Icon(Icons.schedule_rounded, color: Color(0xFFD64545));
    return Icon(Icons.timelapse_rounded, color: scheme.primary);
  }
}
