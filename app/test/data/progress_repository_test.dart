import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordwise/data/progress/progress_db.dart';
import 'package:wordwise/data/progress/progress_repository.dart';
import 'package:wordwise/domain/models.dart';
import 'package:wordwise/domain/scheduler.dart';

Word w(int id) => Word(id: id, lemma: 'w$id', band: (id - 1) ~/ 1000 + 1, zipf: 5, ipa: null, isProper: false, isAbbrev: false, pos: const ['noun']);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late ProgressDb db;
  late ProgressRepository repo;
  final now = DateTime(2026, 9, 12, 12);

  setUp(() {
    db = ProgressDb(NativeDatabase.memory());
    repo = ProgressRepository(db);
  });
  tearDown(() => db.close());

  Future<Progress> swipe(int id, Grade g, {DateTime? at}) async {
    final before = await repo.get(id);
    final after = applyGrade(previous: before, wordId: id, lemma: 'w$id', grade: g, now: at ?? now);
    await repo.recordSwipe(before: before, after: after, grade: g);
    return after;
  }

  test('swipe persists and is due later', () async {
    await swipe(1, Grade.unknown);
    expect((await repo.get(1))!.lapseCount, 1);
    expect(await repo.due(now), isEmpty);
    expect(await repo.due(now.add(const Duration(minutes: 10))), hasLength(1));
    expect(await repo.dueCount(now.add(const Duration(hours: 1))), 1);
  });

  test('undo restores the previous row, or deletes a new one', () async {
    await swipe(1, Grade.unknown);
    await swipe(1, Grade.issues, at: now.add(const Duration(days: 1)));
    var last = await repo.lastSwipe();
    expect(last!.grade, 'issues');
    await repo.revert(last);
    expect((await repo.get(1))!.interval, const Duration(minutes: 10));
    last = await repo.lastSwipe();
    await repo.revert(last!);
    expect(await repo.get(1), isNull);
    expect(await repo.lastSwipe(), isNull);
  });

  test('today stats: introductions are swipes without a before row', () async {
    await swipe(1, Grade.know);
    await swipe(2, Grade.unknown);
    await swipe(2, Grade.issues, at: now.add(const Duration(minutes: 15)));
    final today = await repo.swipesSince(now);
    expect(today.where((e) => e.before == null).length, 2);
    expect(today.length, 3);
  });

  test('bulk retire skips words with progress and can be undone', () async {
    await swipe(3, Grade.unknown);
    final n = await repo.bulkRetire([w(1), w(2), w(3), w(4)], now);
    expect(n, 3);
    expect(await repo.countByState(ProgressState.retired), 3);
    expect((await repo.get(3))!.isRetired, isFalse);
    final entry = await repo.lastBulkRetire();
    expect(await repo.undoBulkRetire(entry!), 3);
    expect(await repo.countByState(ProgressState.retired), 0);
    expect(await repo.lastBulkRetire(), isNull);
  });

  test('retire / un-retire from the list', () async {
    await repo.setRetired(w(5), true, now);
    expect((await repo.get(5))!.retiredBy, RetiredBy.list);
    await repo.setRetired(w(5), false, now);
    expect(await repo.get(5), isNull, reason: 'no history → new again');

    await swipe(6, Grade.issues);
    await repo.setRetired(w(6), true, now);
    await repo.setRetired(w(6), false, now);
    final p = await repo.get(6);
    expect(p!.state, ProgressState.learning);
    expect(p.isDue(now), isTrue);
  });

  test('export / import merges by lemma with newest wins', () async {
    await swipe(1, Grade.issues);
    final data = await repo.export();
    await swipe(1, Grade.unknown, at: now.add(const Duration(days: 2)));
    final merged = await repo.import(data, (lemma) => lemma == 'w1' ? 1 : null);
    expect(merged, 0, reason: 'local is newer');
    expect((await repo.get(1))!.lapseCount, 1);

    final older = {...data, 'progress': [(data['progress'] as List).first as Map<String, Object?>]};
    final fresh = ProgressRepository(ProgressDb(NativeDatabase.memory()));
    expect(await fresh.import(older, (l) => 7), 1);
    expect((await fresh.get(7))!.lemma, 'w1');
  });

  test('settings round-trip', () async {
    expect(await repo.setting('new_per_day'), isNull);
    await repo.setSetting('new_per_day', '30');
    await repo.setSetting('new_per_day', '40');
    expect(await repo.setting('new_per_day'), '40');
  });
}
