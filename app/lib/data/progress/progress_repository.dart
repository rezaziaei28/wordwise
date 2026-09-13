import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models.dart';
import 'progress_db.dart';

/// One `review_log` row, decoded.
class LogEntry {
  const LogEntry({
    required this.id,
    required this.wordId,
    required this.lemma,
    required this.grade,
    required this.at,
    required this.before,
    required this.after,
  });

  final int id;
  final int wordId;
  final String lemma;

  /// A [Grade] name, or `bulk_retire` / `unretire` / `retire`.
  final String grade;
  final DateTime at;
  final Progress? before;
  final Map<String, Object?> after;

  static const bulkRetire = 'bulk_retire';
  static const unretire = 'unretire';
  static const retire = 'retire';
  static const skip = 'skip';

  bool get isSwipe => Grade.values.any((g) => g.name == grade);
}

class ProgressRepository {
  ProgressRepository(this.db);

  final ProgressDb db;

  // ---- mapping -----------------------------------------------------------

  Progress _fromRow(ProgressRow r) => Progress(
        wordId: r.wordId,
        lemma: r.lemma,
        state: ProgressState.values.byName(r.state),
        interval: Duration(minutes: r.intervalMin),
        dueAt: r.dueAt == null ? null : DateTime.fromMillisecondsSinceEpoch(r.dueAt!),
        seenCount: r.seenCount,
        lapseCount: r.lapseCount,
        retiredBy: r.retiredBy == null ? null : RetiredBy.values.byName(r.retiredBy!),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
      );

  ProgressRowsCompanion _toCompanion(Progress p) => ProgressRowsCompanion.insert(
        wordId: Value(p.wordId),
        lemma: p.lemma,
        state: p.state.name,
        intervalMin: Value(p.interval.inMinutes),
        dueAt: Value(p.dueAt?.millisecondsSinceEpoch),
        seenCount: Value(p.seenCount),
        lapseCount: Value(p.lapseCount),
        retiredBy: Value(p.retiredBy?.name),
        updatedAt: p.updatedAt.millisecondsSinceEpoch,
      );

  LogEntry _log(ReviewLogRow r) => LogEntry(
        id: r.id,
        wordId: r.wordId,
        lemma: r.lemma,
        grade: r.grade,
        at: DateTime.fromMillisecondsSinceEpoch(r.at),
        before: r.beforeJson == null ? null : Progress.fromJson(jsonDecode(r.beforeJson!) as Map<String, Object?>),
        after: jsonDecode(r.afterJson) as Map<String, Object?>,
      );

  // ---- reads -------------------------------------------------------------

  Future<Progress?> get(int wordId) async {
    final r = await (db.select(db.progressRows)..where((t) => t.wordId.equals(wordId))).getSingleOrNull();
    return r == null ? null : _fromRow(r);
  }

  Future<Map<int, Progress>> getMany(Iterable<int> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return const {};
    final rows = await (db.select(db.progressRows)..where((t) => t.wordId.isIn(list))).get();
    return {for (final r in rows) r.wordId: _fromRow(r)};
  }

  Future<List<Progress>> due(DateTime now, {int limit = 100}) async {
    final rows = await (db.select(db.progressRows)
          ..where((t) => t.state.equals(ProgressState.learning.name) & t.dueAt.isSmallerOrEqualValue(now.millisecondsSinceEpoch))
          ..orderBy([(t) => OrderingTerm.asc(t.dueAt)])
          ..limit(limit))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<int> dueCount(DateTime now) async {
    final c = db.progressRows.wordId.count();
    final q = db.selectOnly(db.progressRows)
      ..addColumns([c])
      ..where(db.progressRows.state.equals(ProgressState.learning.name) & db.progressRows.dueAt.isSmallerOrEqualValue(now.millisecondsSinceEpoch));
    return (await q.getSingle()).read(c) ?? 0;
  }

  Future<int> countByState(ProgressState state) async {
    final c = db.progressRows.wordId.count();
    final q = db.selectOnly(db.progressRows)
      ..addColumns([c])
      ..where(db.progressRows.state.equals(state.name));
    return (await q.getSingle()).read(c) ?? 0;
  }

  /// Retired word ids — the caller derives bands from ids (id == rank).
  Future<List<int>> retiredIds() async {
    final rows = await (db.selectOnly(db.progressRows)
          ..addColumns([db.progressRows.wordId])
          ..where(db.progressRows.state.equals(ProgressState.retired.name)))
        .get();
    return rows.map((r) => r.read(db.progressRows.wordId)!).toList();
  }

  Future<List<int>> idsByState(ProgressState state, {required int offset, required int limit}) async {
    final rows = await (db.select(db.progressRows)
          ..where((t) => t.state.equals(state.name))
          ..orderBy([(t) => OrderingTerm.asc(t.wordId)])
          ..limit(limit, offset: offset))
        .get();
    return rows.map((r) => r.wordId).toList();
  }

  Future<List<LogEntry>> history(int wordId, {int limit = 10}) async {
    final rows = await (db.select(db.reviewLogRows)
          ..where((t) => t.wordId.equals(wordId))
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(limit))
        .get();
    return rows.map(_log).toList();
  }

  Future<LogEntry?> lastSwipe() async {
    final r = await (db.select(db.reviewLogRows)
          ..where((t) => t.grade.isIn(Grade.values.map((g) => g.name).toList()))
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    return r == null ? null : _log(r);
  }

  Future<LogEntry?> lastBulkRetire() async {
    final r = await (db.select(db.reviewLogRows)
          ..where((t) => t.grade.equals(LogEntry.bulkRetire))
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    return r == null ? null : _log(r);
  }

  /// Swipes since [since]; new-word introductions are those with no `before`.
  Future<List<LogEntry>> swipesSince(DateTime since) async {
    final rows = await (db.select(db.reviewLogRows)
          ..where((t) => t.at.isBiggerOrEqualValue(since.millisecondsSinceEpoch) & t.grade.isIn(Grade.values.map((g) => g.name).toList()))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return rows.map(_log).toList();
  }

  /// Most recent swipes, newest first.
  Future<List<LogEntry>> recentSwipes({int limit = 50}) async {
    final rows = await (db.select(db.reviewLogRows)
          ..where((t) => t.grade.isIn(Grade.values.map((g) => g.name).toList()))
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(limit))
        .get();
    return rows.map(_log).toList();
  }

  // ---- writes ------------------------------------------------------------

  /// Streak rule: mark unseen [words] as skipped in one transaction with one
  /// log entry (grade `skip`, word ids in `after`).
  Future<int> skipWords(List<Word> words, DateTime now) => db.transaction(() async {
        final existing = await getMany(words.map((w) => w.id));
        final fresh = words.where((w) => !existing.containsKey(w.id)).toList();
        await db.batch((b) {
          for (final w in fresh) {
            b.insert(
              db.progressRows,
              _toCompanion(Progress(
                wordId: w.id,
                lemma: w.lemma,
                state: ProgressState.skipped,
                interval: Duration.zero,
                dueAt: null,
                seenCount: 0,
                lapseCount: 0,
                retiredBy: null,
                updatedAt: now,
              )),
            );
          }
        });
        if (fresh.isNotEmpty) {
          await db.into(db.reviewLogRows).insert(ReviewLogRowsCompanion.insert(
                wordId: fresh.first.id,
                lemma: fresh.first.lemma,
                grade: LogEntry.skip,
                at: now.millisecondsSinceEpoch,
                afterJson: jsonEncode({'word_ids': fresh.map((w) => w.id).toList()}),
              ));
        }
        return fresh.length;
      });


  /// Persist a swipe: upsert the progress row and append the log entry.
  Future<void> recordSwipe({required Progress? before, required Progress after, required Grade grade}) =>
      db.transaction(() async {
        await db.into(db.progressRows).insertOnConflictUpdate(_toCompanion(after));
        await db.into(db.reviewLogRows).insert(ReviewLogRowsCompanion.insert(
              wordId: after.wordId,
              lemma: after.lemma,
              grade: grade.name,
              at: after.updatedAt.millisecondsSinceEpoch,
              beforeJson: Value(before == null ? null : jsonEncode(before.toJson())),
              afterJson: jsonEncode(after.toJson()),
            ));
      });

  /// Reverse one log entry: restore `before` (or delete the row) and drop the entry.
  Future<void> revert(LogEntry entry) => db.transaction(() async {
        if (entry.before == null) {
          await (db.delete(db.progressRows)..where((t) => t.wordId.equals(entry.wordId))).go();
        } else {
          await db.into(db.progressRows).insertOnConflictUpdate(_toCompanion(entry.before!));
        }
        await (db.delete(db.reviewLogRows)..where((t) => t.id.equals(entry.id))).go();
      });

  /// Retire or un-retire from the word list (F5). Un-retiring a word with
  /// history puts it back into learning, due now; without history it becomes new.
  Future<void> setRetired(Word word, bool retired, DateTime now) => db.transaction(() async {
        final before = await get(word.id);
        Progress? after;
        if (retired) {
          after = (before ??
                  Progress(
                    wordId: word.id,
                    lemma: word.lemma,
                    state: ProgressState.learning,
                    interval: Duration.zero,
                    dueAt: null,
                    seenCount: 0,
                    lapseCount: 0,
                    retiredBy: null,
                    updatedAt: now,
                  ))
              .copyWith(state: ProgressState.retired, dueAt: () => null, retiredBy: () => RetiredBy.list, updatedAt: now);
          await db.into(db.progressRows).insertOnConflictUpdate(_toCompanion(after));
        } else if (before != null && before.seenCount == 0) {
          await (db.delete(db.progressRows)..where((t) => t.wordId.equals(word.id))).go();
        } else if (before != null) {
          after = before.copyWith(state: ProgressState.learning, interval: Duration.zero, dueAt: () => now, retiredBy: () => null, updatedAt: now);
          await db.into(db.progressRows).insertOnConflictUpdate(_toCompanion(after));
        }
        await db.into(db.reviewLogRows).insert(ReviewLogRowsCompanion.insert(
              wordId: word.id,
              lemma: word.lemma,
              grade: retired ? LogEntry.retire : LogEntry.unretire,
              at: now.millisecondsSinceEpoch,
              beforeJson: Value(before == null ? null : jsonEncode(before.toJson())),
              afterJson: jsonEncode(after?.toJson() ?? const <String, Object?>{}),
            ));
      });

  /// Calibration: retire every word in [words] that has no progress yet, as
  /// one transaction and one log entry so it can be undone as a whole.
  Future<int> bulkRetire(List<Word> words, DateTime now) => db.transaction(() async {
        final existing = await getMany(words.map((w) => w.id));
        final fresh = words.where((w) => !existing.containsKey(w.id)).toList();
        await db.batch((b) {
          for (final w in fresh) {
            b.insert(
              db.progressRows,
              _toCompanion(Progress(
                wordId: w.id,
                lemma: w.lemma,
                state: ProgressState.retired,
                interval: Duration.zero,
                dueAt: null,
                seenCount: 0,
                lapseCount: 0,
                retiredBy: RetiredBy.bulk,
                updatedAt: now,
              )),
            );
          }
        });
        if (fresh.isNotEmpty) {
          await db.into(db.reviewLogRows).insert(ReviewLogRowsCompanion.insert(
                wordId: fresh.first.id,
                lemma: fresh.first.lemma,
                grade: LogEntry.bulkRetire,
                at: now.millisecondsSinceEpoch,
                afterJson: jsonEncode({'word_ids': fresh.map((w) => w.id).toList()}),
              ));
        }
        return fresh.length;
      });

  Future<int> undoBulkRetire(LogEntry entry) => db.transaction(() async {
        final ids = (entry.after['word_ids'] as List).cast<int>();
        final n = await (db.delete(db.progressRows)
              ..where((t) => t.wordId.isIn(ids) & t.retiredBy.equals(RetiredBy.bulk.name)))
            .go();
        await (db.delete(db.reviewLogRows)..where((t) => t.id.equals(entry.id))).go();
        return n;
      });

  // ---- settings ----------------------------------------------------------

  Future<String?> setting(String key) async {
    final r = await (db.select(db.settingRows)..where((t) => t.key.equals(key))).getSingleOrNull();
    return r?.value;
  }

  Future<void> setSetting(String key, String value) =>
      db.into(db.settingRows).insertOnConflictUpdate(SettingRowsCompanion.insert(key: key, value: value));

  Future<Map<String, String>> allSettings() async =>
      {for (final r in await db.select(db.settingRows).get()) r.key: r.value};

  // ---- export / import ---------------------------------------------------

  Future<Map<String, Object?>> export() async {
    final rows = await db.select(db.progressRows).get();
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'progress': rows.map((r) => _fromRow(r).toJson()).toList(),
      'settings': await allSettings(),
    };
  }

  /// Merge by lemma, newest `updated_at` wins. [resolveId] maps a lemma to
  /// the current dictionary id (null = not in this dictionary → skipped).
  Future<int> import(Map<String, Object?> data, int? Function(String lemma) resolveId) => db.transaction(() async {
        var merged = 0;
        for (final raw in (data['progress'] as List).cast<Map<String, Object?>>()) {
          final id = resolveId(raw['lemma'] as String);
          if (id == null) continue;
          final incoming = Progress.fromJson({...raw, 'word_id': id});
          final current = await get(id);
          if (current != null && !incoming.updatedAt.isAfter(current.updatedAt)) continue;
          await db.into(db.progressRows).insertOnConflictUpdate(_toCompanion(incoming));
          merged++;
        }
        for (final e in ((data['settings'] as Map?) ?? const {}).entries) {
          await setSetting(e.key as String, e.value as String);
        }
        return merged;
      });
}
