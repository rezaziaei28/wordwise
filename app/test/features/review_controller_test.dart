import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordwise/core/providers.dart';
import 'package:wordwise/core/settings.dart';
import 'package:wordwise/data/progress/progress_db.dart';
import 'package:wordwise/domain/models.dart';
import 'package:wordwise/features/review/review_controller.dart';

import '../support/test_dictionary.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late ProviderContainer container;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 9, 12, 9);
    container = ProviderContainer(overrides: [
      dictionaryProvider.overrideWithValue(testDictionary(n: 100)),
      progressDbProvider.overrideWithValue(ProgressDb(NativeDatabase.memory())),
      ttsProvider.overrideWithValue(Tts.noop()),
      clockProvider.overrideWithValue(() => now),
    ]);
  });
  tearDown(() => container.dispose());

  Future<ReviewState> state() => container.read(reviewControllerProvider.future);
  ReviewController ctrl() => container.read(reviewControllerProvider.notifier);

  test('starts with rank 1 and pre-loads the next card', () async {
    final s = await state();
    expect(s.current!.word.id, 1);
    expect(s.next!.word.id, 2);
    expect(s.current!.isNew, isTrue);
    expect(s.canUndo, isFalse);
  });

  test('swipes advance in rank order and count today', () async {
    await state();
    await ctrl().swipe(Grade.know);
    await ctrl().swipe(Grade.issues);
    final s = await state();
    expect(s.current!.word.id, 3);
    expect(s.doneToday, 2);
    expect(s.newToday, 2);
    expect(s.canUndo, isTrue);
  });

  test('undo brings the card back', () async {
    await state();
    await ctrl().swipe(Grade.know);
    await ctrl().undo();
    final s = await state();
    expect(s.current!.word.id, 1);
    expect(s.doneToday, 0);
    expect(await container.read(progressRepositoryProvider).get(1), isNull);
  });

  test('an unknown word returns within the session', () async {
    await state();
    await ctrl().swipe(Grade.unknown); // w1
    final seen = <int>[];
    for (var i = 0; i < 25; i++) {
      seen.add((await state()).current!.word.id);
      await ctrl().swipe(Grade.know);
    }
    expect(seen.where((id) => id == 1), hasLength(1), reason: 'w1 came back once');
    expect(seen.indexOf(1), inInclusiveRange(15, 22));
  });

  test('due reviews come before new words after a restart', () async {
    await state();
    await ctrl().swipe(Grade.issues); // w1 due in a day
    await ctrl().swipe(Grade.know); // w2
    now = now.add(const Duration(days: 2));
    await ctrl().refresh();
    final s = await state();
    expect(s.current!.word.id, 1);
    expect(s.current!.isNew, isFalse);
    expect(s.next!.word.id, 3);
    expect(s.dueNow, 1);
  });

  test('daily cap is soft', () async {
    await container.read(settingsProvider.future);
    await container.read(settingsProvider.notifier).setNewPerDay(3);
    await state();
    for (var i = 0; i < 3; i++) {
      await ctrl().swipe(Grade.know);
    }
    var s = await state();
    expect(s.current, isNull);
    expect(s.newCapReached, isTrue);
    await ctrl().continuePastCap();
    s = await state();
    expect(s.current!.word.id, 4);
    expect(s.newCapReached, isFalse);
  });

  test('resumes at the same card after a restart and never skips', () async {
    await state();
    await ctrl().swipe(Grade.know);
    await ctrl().swipe(Grade.know);
    expect((await state()).current!.word.id, 3);
    await ctrl().refresh();
    expect((await state()).current!.word.id, 3);
    expect(await container.read(progressRepositoryProvider).setting(SettingKeys.nextNewRank), '2');
  });

  test('exhausts a small dictionary', () async {
    await container.read(settingsProvider.future);
    await container.read(settingsProvider.notifier).setNewPerDay(500);
    await state();
    for (var i = 0; i < 100; i++) {
      await ctrl().swipe(Grade.know);
    }
    final s = await state();
    expect(s.current, isNull);
    expect(s.exhausted, isTrue);
  });
}
