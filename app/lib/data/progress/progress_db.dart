import 'package:drift/drift.dart';

part 'progress_db.g.dart';

/// Learner state per word; absence of a row means "new" (tech §4.2).
class ProgressRows extends Table {
  @override
  String get tableName => 'progress';

  IntColumn get wordId => integer()();
  TextColumn get lemma => text()();
  TextColumn get state => text()();
  IntColumn get intervalMin => integer().withDefault(const Constant(0))();
  IntColumn get dueAt => integer().nullable()();
  IntColumn get seenCount => integer().withDefault(const Constant(0))();
  IntColumn get lapseCount => integer().withDefault(const Constant(0))();
  TextColumn get retiredBy => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {wordId};
}

/// Append-only history: drives undo, stats and (later) sync.
class ReviewLogRows extends Table {
  @override
  String get tableName => 'review_log';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer()();
  TextColumn get lemma => text()();
  TextColumn get grade => text()();
  IntColumn get at => integer()();
  TextColumn get beforeJson => text().nullable()();
  TextColumn get afterJson => text()();
}

class SettingRows extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [ProgressRows, ReviewLogRows, SettingRows])
class ProgressDb extends _$ProgressDb {
  ProgressDb(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX progress_due ON progress(state, due_at)');
          await customStatement('CREATE INDEX review_log_at ON review_log(at)');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
