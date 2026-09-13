// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_db.dart';

// ignore_for_file: type=lint
class $ProgressRowsTable extends ProgressRows
    with TableInfo<$ProgressRowsTable, ProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lemmaMeta = const VerificationMeta('lemma');
  @override
  late final GeneratedColumn<String> lemma = GeneratedColumn<String>(
    'lemma',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalMinMeta = const VerificationMeta(
    'intervalMin',
  );
  @override
  late final GeneratedColumn<int> intervalMin = GeneratedColumn<int>(
    'interval_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seenCountMeta = const VerificationMeta(
    'seenCount',
  );
  @override
  late final GeneratedColumn<int> seenCount = GeneratedColumn<int>(
    'seen_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapseCountMeta = const VerificationMeta(
    'lapseCount',
  );
  @override
  late final GeneratedColumn<int> lapseCount = GeneratedColumn<int>(
    'lapse_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retiredByMeta = const VerificationMeta(
    'retiredBy',
  );
  @override
  late final GeneratedColumn<String> retiredBy = GeneratedColumn<String>(
    'retired_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    wordId,
    lemma,
    state,
    intervalMin,
    dueAt,
    seenCount,
    lapseCount,
    retiredBy,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    }
    if (data.containsKey('lemma')) {
      context.handle(
        _lemmaMeta,
        lemma.isAcceptableOrUnknown(data['lemma']!, _lemmaMeta),
      );
    } else if (isInserting) {
      context.missing(_lemmaMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('interval_min')) {
      context.handle(
        _intervalMinMeta,
        intervalMin.isAcceptableOrUnknown(
          data['interval_min']!,
          _intervalMinMeta,
        ),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('seen_count')) {
      context.handle(
        _seenCountMeta,
        seenCount.isAcceptableOrUnknown(data['seen_count']!, _seenCountMeta),
      );
    }
    if (data.containsKey('lapse_count')) {
      context.handle(
        _lapseCountMeta,
        lapseCount.isAcceptableOrUnknown(data['lapse_count']!, _lapseCountMeta),
      );
    }
    if (data.containsKey('retired_by')) {
      context.handle(
        _retiredByMeta,
        retiredBy.isAcceptableOrUnknown(data['retired_by']!, _retiredByMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  ProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressRow(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      lemma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lemma'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      intervalMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_min'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      ),
      seenCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seen_count'],
      )!,
      lapseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapse_count'],
      )!,
      retiredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}retired_by'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProgressRowsTable createAlias(String alias) {
    return $ProgressRowsTable(attachedDatabase, alias);
  }
}

class ProgressRow extends DataClass implements Insertable<ProgressRow> {
  final int wordId;
  final String lemma;
  final String state;
  final int intervalMin;
  final int? dueAt;
  final int seenCount;
  final int lapseCount;
  final String? retiredBy;
  final int updatedAt;
  const ProgressRow({
    required this.wordId,
    required this.lemma,
    required this.state,
    required this.intervalMin,
    this.dueAt,
    required this.seenCount,
    required this.lapseCount,
    this.retiredBy,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['lemma'] = Variable<String>(lemma);
    map['state'] = Variable<String>(state);
    map['interval_min'] = Variable<int>(intervalMin);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<int>(dueAt);
    }
    map['seen_count'] = Variable<int>(seenCount);
    map['lapse_count'] = Variable<int>(lapseCount);
    if (!nullToAbsent || retiredBy != null) {
      map['retired_by'] = Variable<String>(retiredBy);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProgressRowsCompanion toCompanion(bool nullToAbsent) {
    return ProgressRowsCompanion(
      wordId: Value(wordId),
      lemma: Value(lemma),
      state: Value(state),
      intervalMin: Value(intervalMin),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      seenCount: Value(seenCount),
      lapseCount: Value(lapseCount),
      retiredBy: retiredBy == null && nullToAbsent
          ? const Value.absent()
          : Value(retiredBy),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressRow(
      wordId: serializer.fromJson<int>(json['wordId']),
      lemma: serializer.fromJson<String>(json['lemma']),
      state: serializer.fromJson<String>(json['state']),
      intervalMin: serializer.fromJson<int>(json['intervalMin']),
      dueAt: serializer.fromJson<int?>(json['dueAt']),
      seenCount: serializer.fromJson<int>(json['seenCount']),
      lapseCount: serializer.fromJson<int>(json['lapseCount']),
      retiredBy: serializer.fromJson<String?>(json['retiredBy']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'lemma': serializer.toJson<String>(lemma),
      'state': serializer.toJson<String>(state),
      'intervalMin': serializer.toJson<int>(intervalMin),
      'dueAt': serializer.toJson<int?>(dueAt),
      'seenCount': serializer.toJson<int>(seenCount),
      'lapseCount': serializer.toJson<int>(lapseCount),
      'retiredBy': serializer.toJson<String?>(retiredBy),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ProgressRow copyWith({
    int? wordId,
    String? lemma,
    String? state,
    int? intervalMin,
    Value<int?> dueAt = const Value.absent(),
    int? seenCount,
    int? lapseCount,
    Value<String?> retiredBy = const Value.absent(),
    int? updatedAt,
  }) => ProgressRow(
    wordId: wordId ?? this.wordId,
    lemma: lemma ?? this.lemma,
    state: state ?? this.state,
    intervalMin: intervalMin ?? this.intervalMin,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    seenCount: seenCount ?? this.seenCount,
    lapseCount: lapseCount ?? this.lapseCount,
    retiredBy: retiredBy.present ? retiredBy.value : this.retiredBy,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProgressRow copyWithCompanion(ProgressRowsCompanion data) {
    return ProgressRow(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      lemma: data.lemma.present ? data.lemma.value : this.lemma,
      state: data.state.present ? data.state.value : this.state,
      intervalMin: data.intervalMin.present
          ? data.intervalMin.value
          : this.intervalMin,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      seenCount: data.seenCount.present ? data.seenCount.value : this.seenCount,
      lapseCount: data.lapseCount.present
          ? data.lapseCount.value
          : this.lapseCount,
      retiredBy: data.retiredBy.present ? data.retiredBy.value : this.retiredBy,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressRow(')
          ..write('wordId: $wordId, ')
          ..write('lemma: $lemma, ')
          ..write('state: $state, ')
          ..write('intervalMin: $intervalMin, ')
          ..write('dueAt: $dueAt, ')
          ..write('seenCount: $seenCount, ')
          ..write('lapseCount: $lapseCount, ')
          ..write('retiredBy: $retiredBy, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    wordId,
    lemma,
    state,
    intervalMin,
    dueAt,
    seenCount,
    lapseCount,
    retiredBy,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressRow &&
          other.wordId == this.wordId &&
          other.lemma == this.lemma &&
          other.state == this.state &&
          other.intervalMin == this.intervalMin &&
          other.dueAt == this.dueAt &&
          other.seenCount == this.seenCount &&
          other.lapseCount == this.lapseCount &&
          other.retiredBy == this.retiredBy &&
          other.updatedAt == this.updatedAt);
}

class ProgressRowsCompanion extends UpdateCompanion<ProgressRow> {
  final Value<int> wordId;
  final Value<String> lemma;
  final Value<String> state;
  final Value<int> intervalMin;
  final Value<int?> dueAt;
  final Value<int> seenCount;
  final Value<int> lapseCount;
  final Value<String?> retiredBy;
  final Value<int> updatedAt;
  const ProgressRowsCompanion({
    this.wordId = const Value.absent(),
    this.lemma = const Value.absent(),
    this.state = const Value.absent(),
    this.intervalMin = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.seenCount = const Value.absent(),
    this.lapseCount = const Value.absent(),
    this.retiredBy = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProgressRowsCompanion.insert({
    this.wordId = const Value.absent(),
    required String lemma,
    required String state,
    this.intervalMin = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.seenCount = const Value.absent(),
    this.lapseCount = const Value.absent(),
    this.retiredBy = const Value.absent(),
    required int updatedAt,
  }) : lemma = Value(lemma),
       state = Value(state),
       updatedAt = Value(updatedAt);
  static Insertable<ProgressRow> custom({
    Expression<int>? wordId,
    Expression<String>? lemma,
    Expression<String>? state,
    Expression<int>? intervalMin,
    Expression<int>? dueAt,
    Expression<int>? seenCount,
    Expression<int>? lapseCount,
    Expression<String>? retiredBy,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (lemma != null) 'lemma': lemma,
      if (state != null) 'state': state,
      if (intervalMin != null) 'interval_min': intervalMin,
      if (dueAt != null) 'due_at': dueAt,
      if (seenCount != null) 'seen_count': seenCount,
      if (lapseCount != null) 'lapse_count': lapseCount,
      if (retiredBy != null) 'retired_by': retiredBy,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProgressRowsCompanion copyWith({
    Value<int>? wordId,
    Value<String>? lemma,
    Value<String>? state,
    Value<int>? intervalMin,
    Value<int?>? dueAt,
    Value<int>? seenCount,
    Value<int>? lapseCount,
    Value<String?>? retiredBy,
    Value<int>? updatedAt,
  }) {
    return ProgressRowsCompanion(
      wordId: wordId ?? this.wordId,
      lemma: lemma ?? this.lemma,
      state: state ?? this.state,
      intervalMin: intervalMin ?? this.intervalMin,
      dueAt: dueAt ?? this.dueAt,
      seenCount: seenCount ?? this.seenCount,
      lapseCount: lapseCount ?? this.lapseCount,
      retiredBy: retiredBy ?? this.retiredBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (lemma.present) {
      map['lemma'] = Variable<String>(lemma.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (intervalMin.present) {
      map['interval_min'] = Variable<int>(intervalMin.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (seenCount.present) {
      map['seen_count'] = Variable<int>(seenCount.value);
    }
    if (lapseCount.present) {
      map['lapse_count'] = Variable<int>(lapseCount.value);
    }
    if (retiredBy.present) {
      map['retired_by'] = Variable<String>(retiredBy.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressRowsCompanion(')
          ..write('wordId: $wordId, ')
          ..write('lemma: $lemma, ')
          ..write('state: $state, ')
          ..write('intervalMin: $intervalMin, ')
          ..write('dueAt: $dueAt, ')
          ..write('seenCount: $seenCount, ')
          ..write('lapseCount: $lapseCount, ')
          ..write('retiredBy: $retiredBy, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogRowsTable extends ReviewLogRows
    with TableInfo<$ReviewLogRowsTable, ReviewLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lemmaMeta = const VerificationMeta('lemma');
  @override
  late final GeneratedColumn<String> lemma = GeneratedColumn<String>(
    'lemma',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beforeJsonMeta = const VerificationMeta(
    'beforeJson',
  );
  @override
  late final GeneratedColumn<String> beforeJson = GeneratedColumn<String>(
    'before_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _afterJsonMeta = const VerificationMeta(
    'afterJson',
  );
  @override
  late final GeneratedColumn<String> afterJson = GeneratedColumn<String>(
    'after_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wordId,
    lemma,
    grade,
    at,
    beforeJson,
    afterJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('lemma')) {
      context.handle(
        _lemmaMeta,
        lemma.isAcceptableOrUnknown(data['lemma']!, _lemmaMeta),
      );
    } else if (isInserting) {
      context.missing(_lemmaMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('before_json')) {
      context.handle(
        _beforeJsonMeta,
        beforeJson.isAcceptableOrUnknown(data['before_json']!, _beforeJsonMeta),
      );
    }
    if (data.containsKey('after_json')) {
      context.handle(
        _afterJsonMeta,
        afterJson.isAcceptableOrUnknown(data['after_json']!, _afterJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_afterJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      lemma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lemma'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at'],
      )!,
      beforeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}before_json'],
      ),
      afterJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}after_json'],
      )!,
    );
  }

  @override
  $ReviewLogRowsTable createAlias(String alias) {
    return $ReviewLogRowsTable(attachedDatabase, alias);
  }
}

class ReviewLogRow extends DataClass implements Insertable<ReviewLogRow> {
  final int id;
  final int wordId;
  final String lemma;
  final String grade;
  final int at;
  final String? beforeJson;
  final String afterJson;
  const ReviewLogRow({
    required this.id,
    required this.wordId,
    required this.lemma,
    required this.grade,
    required this.at,
    this.beforeJson,
    required this.afterJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['lemma'] = Variable<String>(lemma);
    map['grade'] = Variable<String>(grade);
    map['at'] = Variable<int>(at);
    if (!nullToAbsent || beforeJson != null) {
      map['before_json'] = Variable<String>(beforeJson);
    }
    map['after_json'] = Variable<String>(afterJson);
    return map;
  }

  ReviewLogRowsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogRowsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      lemma: Value(lemma),
      grade: Value(grade),
      at: Value(at),
      beforeJson: beforeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(beforeJson),
      afterJson: Value(afterJson),
    );
  }

  factory ReviewLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLogRow(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      lemma: serializer.fromJson<String>(json['lemma']),
      grade: serializer.fromJson<String>(json['grade']),
      at: serializer.fromJson<int>(json['at']),
      beforeJson: serializer.fromJson<String?>(json['beforeJson']),
      afterJson: serializer.fromJson<String>(json['afterJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'lemma': serializer.toJson<String>(lemma),
      'grade': serializer.toJson<String>(grade),
      'at': serializer.toJson<int>(at),
      'beforeJson': serializer.toJson<String?>(beforeJson),
      'afterJson': serializer.toJson<String>(afterJson),
    };
  }

  ReviewLogRow copyWith({
    int? id,
    int? wordId,
    String? lemma,
    String? grade,
    int? at,
    Value<String?> beforeJson = const Value.absent(),
    String? afterJson,
  }) => ReviewLogRow(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    lemma: lemma ?? this.lemma,
    grade: grade ?? this.grade,
    at: at ?? this.at,
    beforeJson: beforeJson.present ? beforeJson.value : this.beforeJson,
    afterJson: afterJson ?? this.afterJson,
  );
  ReviewLogRow copyWithCompanion(ReviewLogRowsCompanion data) {
    return ReviewLogRow(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      lemma: data.lemma.present ? data.lemma.value : this.lemma,
      grade: data.grade.present ? data.grade.value : this.grade,
      at: data.at.present ? data.at.value : this.at,
      beforeJson: data.beforeJson.present
          ? data.beforeJson.value
          : this.beforeJson,
      afterJson: data.afterJson.present ? data.afterJson.value : this.afterJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogRow(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('lemma: $lemma, ')
          ..write('grade: $grade, ')
          ..write('at: $at, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, wordId, lemma, grade, at, beforeJson, afterJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLogRow &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.lemma == this.lemma &&
          other.grade == this.grade &&
          other.at == this.at &&
          other.beforeJson == this.beforeJson &&
          other.afterJson == this.afterJson);
}

class ReviewLogRowsCompanion extends UpdateCompanion<ReviewLogRow> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<String> lemma;
  final Value<String> grade;
  final Value<int> at;
  final Value<String?> beforeJson;
  final Value<String> afterJson;
  const ReviewLogRowsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.lemma = const Value.absent(),
    this.grade = const Value.absent(),
    this.at = const Value.absent(),
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
  });
  ReviewLogRowsCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    required String lemma,
    required String grade,
    required int at,
    this.beforeJson = const Value.absent(),
    required String afterJson,
  }) : wordId = Value(wordId),
       lemma = Value(lemma),
       grade = Value(grade),
       at = Value(at),
       afterJson = Value(afterJson);
  static Insertable<ReviewLogRow> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<String>? lemma,
    Expression<String>? grade,
    Expression<int>? at,
    Expression<String>? beforeJson,
    Expression<String>? afterJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (lemma != null) 'lemma': lemma,
      if (grade != null) 'grade': grade,
      if (at != null) 'at': at,
      if (beforeJson != null) 'before_json': beforeJson,
      if (afterJson != null) 'after_json': afterJson,
    });
  }

  ReviewLogRowsCompanion copyWith({
    Value<int>? id,
    Value<int>? wordId,
    Value<String>? lemma,
    Value<String>? grade,
    Value<int>? at,
    Value<String?>? beforeJson,
    Value<String>? afterJson,
  }) {
    return ReviewLogRowsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      lemma: lemma ?? this.lemma,
      grade: grade ?? this.grade,
      at: at ?? this.at,
      beforeJson: beforeJson ?? this.beforeJson,
      afterJson: afterJson ?? this.afterJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (lemma.present) {
      map['lemma'] = Variable<String>(lemma.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (beforeJson.present) {
      map['before_json'] = Variable<String>(beforeJson.value);
    }
    if (afterJson.present) {
      map['after_json'] = Variable<String>(afterJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogRowsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('lemma: $lemma, ')
          ..write('grade: $grade, ')
          ..write('at: $at, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson')
          ..write(')'))
        .toString();
  }
}

class $SettingRowsTable extends SettingRows
    with TableInfo<$SettingRowsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingRowsTable createAlias(String alias) {
    return $SettingRowsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingRowsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingRowsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingRowsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ProgressDb extends GeneratedDatabase {
  _$ProgressDb(QueryExecutor e) : super(e);
  $ProgressDbManager get managers => $ProgressDbManager(this);
  late final $ProgressRowsTable progressRows = $ProgressRowsTable(this);
  late final $ReviewLogRowsTable reviewLogRows = $ReviewLogRowsTable(this);
  late final $SettingRowsTable settingRows = $SettingRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    progressRows,
    reviewLogRows,
    settingRows,
  ];
}

typedef $$ProgressRowsTableCreateCompanionBuilder =
    ProgressRowsCompanion Function({
      Value<int> wordId,
      required String lemma,
      required String state,
      Value<int> intervalMin,
      Value<int?> dueAt,
      Value<int> seenCount,
      Value<int> lapseCount,
      Value<String?> retiredBy,
      required int updatedAt,
    });
typedef $$ProgressRowsTableUpdateCompanionBuilder =
    ProgressRowsCompanion Function({
      Value<int> wordId,
      Value<String> lemma,
      Value<String> state,
      Value<int> intervalMin,
      Value<int?> dueAt,
      Value<int> seenCount,
      Value<int> lapseCount,
      Value<String?> retiredBy,
      Value<int> updatedAt,
    });

class $$ProgressRowsTableFilterComposer
    extends Composer<_$ProgressDb, $ProgressRowsTable> {
  $$ProgressRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalMin => $composableBuilder(
    column: $table.intervalMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seenCount => $composableBuilder(
    column: $table.seenCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapseCount => $composableBuilder(
    column: $table.lapseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get retiredBy => $composableBuilder(
    column: $table.retiredBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgressRowsTableOrderingComposer
    extends Composer<_$ProgressDb, $ProgressRowsTable> {
  $$ProgressRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalMin => $composableBuilder(
    column: $table.intervalMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seenCount => $composableBuilder(
    column: $table.seenCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapseCount => $composableBuilder(
    column: $table.lapseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get retiredBy => $composableBuilder(
    column: $table.retiredBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgressRowsTableAnnotationComposer
    extends Composer<_$ProgressDb, $ProgressRowsTable> {
  $$ProgressRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get lemma =>
      $composableBuilder(column: $table.lemma, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get intervalMin => $composableBuilder(
    column: $table.intervalMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get seenCount =>
      $composableBuilder(column: $table.seenCount, builder: (column) => column);

  GeneratedColumn<int> get lapseCount => $composableBuilder(
    column: $table.lapseCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get retiredBy =>
      $composableBuilder(column: $table.retiredBy, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProgressRowsTableTableManager
    extends
        RootTableManager<
          _$ProgressDb,
          $ProgressRowsTable,
          ProgressRow,
          $$ProgressRowsTableFilterComposer,
          $$ProgressRowsTableOrderingComposer,
          $$ProgressRowsTableAnnotationComposer,
          $$ProgressRowsTableCreateCompanionBuilder,
          $$ProgressRowsTableUpdateCompanionBuilder,
          (
            ProgressRow,
            BaseReferences<_$ProgressDb, $ProgressRowsTable, ProgressRow>,
          ),
          ProgressRow,
          PrefetchHooks Function()
        > {
  $$ProgressRowsTableTableManager(_$ProgressDb db, $ProgressRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                Value<String> lemma = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> intervalMin = const Value.absent(),
                Value<int?> dueAt = const Value.absent(),
                Value<int> seenCount = const Value.absent(),
                Value<int> lapseCount = const Value.absent(),
                Value<String?> retiredBy = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ProgressRowsCompanion(
                wordId: wordId,
                lemma: lemma,
                state: state,
                intervalMin: intervalMin,
                dueAt: dueAt,
                seenCount: seenCount,
                lapseCount: lapseCount,
                retiredBy: retiredBy,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                required String lemma,
                required String state,
                Value<int> intervalMin = const Value.absent(),
                Value<int?> dueAt = const Value.absent(),
                Value<int> seenCount = const Value.absent(),
                Value<int> lapseCount = const Value.absent(),
                Value<String?> retiredBy = const Value.absent(),
                required int updatedAt,
              }) => ProgressRowsCompanion.insert(
                wordId: wordId,
                lemma: lemma,
                state: state,
                intervalMin: intervalMin,
                dueAt: dueAt,
                seenCount: seenCount,
                lapseCount: lapseCount,
                retiredBy: retiredBy,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgressRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDb,
      $ProgressRowsTable,
      ProgressRow,
      $$ProgressRowsTableFilterComposer,
      $$ProgressRowsTableOrderingComposer,
      $$ProgressRowsTableAnnotationComposer,
      $$ProgressRowsTableCreateCompanionBuilder,
      $$ProgressRowsTableUpdateCompanionBuilder,
      (
        ProgressRow,
        BaseReferences<_$ProgressDb, $ProgressRowsTable, ProgressRow>,
      ),
      ProgressRow,
      PrefetchHooks Function()
    >;
typedef $$ReviewLogRowsTableCreateCompanionBuilder =
    ReviewLogRowsCompanion Function({
      Value<int> id,
      required int wordId,
      required String lemma,
      required String grade,
      required int at,
      Value<String?> beforeJson,
      required String afterJson,
    });
typedef $$ReviewLogRowsTableUpdateCompanionBuilder =
    ReviewLogRowsCompanion Function({
      Value<int> id,
      Value<int> wordId,
      Value<String> lemma,
      Value<String> grade,
      Value<int> at,
      Value<String?> beforeJson,
      Value<String> afterJson,
    });

class $$ReviewLogRowsTableFilterComposer
    extends Composer<_$ProgressDb, $ReviewLogRowsTable> {
  $$ReviewLogRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get afterJson => $composableBuilder(
    column: $table.afterJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewLogRowsTableOrderingComposer
    extends Composer<_$ProgressDb, $ReviewLogRowsTable> {
  $$ReviewLogRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get afterJson => $composableBuilder(
    column: $table.afterJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewLogRowsTableAnnotationComposer
    extends Composer<_$ProgressDb, $ReviewLogRowsTable> {
  $$ReviewLogRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get lemma =>
      $composableBuilder(column: $table.lemma, builder: (column) => column);

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get afterJson =>
      $composableBuilder(column: $table.afterJson, builder: (column) => column);
}

class $$ReviewLogRowsTableTableManager
    extends
        RootTableManager<
          _$ProgressDb,
          $ReviewLogRowsTable,
          ReviewLogRow,
          $$ReviewLogRowsTableFilterComposer,
          $$ReviewLogRowsTableOrderingComposer,
          $$ReviewLogRowsTableAnnotationComposer,
          $$ReviewLogRowsTableCreateCompanionBuilder,
          $$ReviewLogRowsTableUpdateCompanionBuilder,
          (
            ReviewLogRow,
            BaseReferences<_$ProgressDb, $ReviewLogRowsTable, ReviewLogRow>,
          ),
          ReviewLogRow,
          PrefetchHooks Function()
        > {
  $$ReviewLogRowsTableTableManager(_$ProgressDb db, $ReviewLogRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<String> lemma = const Value.absent(),
                Value<String> grade = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<String?> beforeJson = const Value.absent(),
                Value<String> afterJson = const Value.absent(),
              }) => ReviewLogRowsCompanion(
                id: id,
                wordId: wordId,
                lemma: lemma,
                grade: grade,
                at: at,
                beforeJson: beforeJson,
                afterJson: afterJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordId,
                required String lemma,
                required String grade,
                required int at,
                Value<String?> beforeJson = const Value.absent(),
                required String afterJson,
              }) => ReviewLogRowsCompanion.insert(
                id: id,
                wordId: wordId,
                lemma: lemma,
                grade: grade,
                at: at,
                beforeJson: beforeJson,
                afterJson: afterJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewLogRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDb,
      $ReviewLogRowsTable,
      ReviewLogRow,
      $$ReviewLogRowsTableFilterComposer,
      $$ReviewLogRowsTableOrderingComposer,
      $$ReviewLogRowsTableAnnotationComposer,
      $$ReviewLogRowsTableCreateCompanionBuilder,
      $$ReviewLogRowsTableUpdateCompanionBuilder,
      (
        ReviewLogRow,
        BaseReferences<_$ProgressDb, $ReviewLogRowsTable, ReviewLogRow>,
      ),
      ReviewLogRow,
      PrefetchHooks Function()
    >;
typedef $$SettingRowsTableCreateCompanionBuilder =
    SettingRowsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingRowsTableUpdateCompanionBuilder =
    SettingRowsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingRowsTableFilterComposer
    extends Composer<_$ProgressDb, $SettingRowsTable> {
  $$SettingRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingRowsTableOrderingComposer
    extends Composer<_$ProgressDb, $SettingRowsTable> {
  $$SettingRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingRowsTableAnnotationComposer
    extends Composer<_$ProgressDb, $SettingRowsTable> {
  $$SettingRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingRowsTableTableManager
    extends
        RootTableManager<
          _$ProgressDb,
          $SettingRowsTable,
          SettingRow,
          $$SettingRowsTableFilterComposer,
          $$SettingRowsTableOrderingComposer,
          $$SettingRowsTableAnnotationComposer,
          $$SettingRowsTableCreateCompanionBuilder,
          $$SettingRowsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$ProgressDb, $SettingRowsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingRowsTableTableManager(_$ProgressDb db, $SettingRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingRowsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingRowsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDb,
      $SettingRowsTable,
      SettingRow,
      $$SettingRowsTableFilterComposer,
      $$SettingRowsTableOrderingComposer,
      $$SettingRowsTableAnnotationComposer,
      $$SettingRowsTableCreateCompanionBuilder,
      $$SettingRowsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$ProgressDb, $SettingRowsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $ProgressDbManager {
  final _$ProgressDb _db;
  $ProgressDbManager(this._db);
  $$ProgressRowsTableTableManager get progressRows =>
      $$ProgressRowsTableTableManager(_db, _db.progressRows);
  $$ReviewLogRowsTableTableManager get reviewLogRows =>
      $$ReviewLogRowsTableTableManager(_db, _db.reviewLogRows);
  $$SettingRowsTableTableManager get settingRows =>
      $$SettingRowsTableTableManager(_db, _db.settingRows);
}
