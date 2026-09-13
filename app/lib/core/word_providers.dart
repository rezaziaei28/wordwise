import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'providers.dart';

/// Full entry for one word; dictionary reads are synchronous and ~µs.
final wordDetailProvider = Provider.family<WordDetail, int>((ref, id) => ref.watch(dictionaryProvider).detail(id));

/// Learner state for one word, re-read whenever [progressVersionProvider] bumps.
final wordProgressProvider = FutureProvider.family<Progress?, int>((ref, id) async {
  ref.watch(progressVersionProvider);
  return ref.watch(progressRepositoryProvider).get(id);
});

/// Bumped after any write outside the review controller (list, calibration,
/// import) so dependent screens refresh.
final progressVersionProvider = NotifierProvider<ProgressVersion, int>(ProgressVersion.new);

class ProgressVersion extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}
