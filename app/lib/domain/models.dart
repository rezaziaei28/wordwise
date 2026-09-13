/// Pure domain models. No Flutter or database imports here.
library;

/// A headword from the bundled dictionary. `id == rank` within one build.
class Word {
  const Word({
    required this.id,
    required this.lemma,
    required this.band,
    required this.zipf,
    required this.ipa,
    required this.isProper,
    required this.isAbbrev,
    required this.pos,
  });

  final int id;
  final String lemma;
  final int band;
  final double zipf;
  final String? ipa;
  final bool isProper;
  final bool isAbbrev;
  final List<String> pos;

  int get rank => id;

  @override
  bool operator ==(Object other) => other is Word && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Word(#$id $lemma)';
}

class Sense {
  const Sense({
    required this.ord,
    required this.pos,
    required this.gloss,
    required this.example,
  });

  final int ord;
  final String pos;
  final String gloss;
  final String? example;
}

class WordDetail {
  const WordDetail({
    required this.word,
    required this.senses,
    required this.forms,
  });

  final Word word;
  final List<Sense> senses;
  final List<String> forms;
}

/// The three swipe outcomes (baseline §3).
enum Grade {
  /// "I'm sure I know it" — retire, never show again.
  know,

  /// "I sort of knew it" — repeat later, interval grows.
  issues,

  /// "I did not know it" — repeat soon, interval resets.
  unknown,
}

/// `skipped`: jumped over by the streak rule, never actually graded.
enum ProgressState { learning, retired, skipped }

/// How a word got retired; `bulk` entries can be undone as a group.
enum RetiredBy { swipe, bulk, list }

/// Learner state for one word. Absence of a row means "new".
class Progress {
  const Progress({
    required this.wordId,
    required this.lemma,
    required this.state,
    required this.interval,
    required this.dueAt,
    required this.seenCount,
    required this.lapseCount,
    required this.retiredBy,
    required this.updatedAt,
  });

  final int wordId;
  final String lemma;
  final ProgressState state;

  /// Current repetition interval. `Duration.zero` = never scheduled.
  final Duration interval;
  final DateTime? dueAt;
  final int seenCount;

  /// Times graded [Grade.unknown].
  final int lapseCount;
  final RetiredBy? retiredBy;
  final DateTime updatedAt;

  bool get isRetired => state == ProgressState.retired;
  bool get isSkipped => state == ProgressState.skipped;
  bool isDue(DateTime now) =>
      state == ProgressState.learning && dueAt != null && !dueAt!.isAfter(now);

  Progress copyWith({
    ProgressState? state,
    Duration? interval,
    DateTime? Function()? dueAt,
    int? seenCount,
    int? lapseCount,
    RetiredBy? Function()? retiredBy,
    DateTime? updatedAt,
  }) =>
      Progress(
        wordId: wordId,
        lemma: lemma,
        state: state ?? this.state,
        interval: interval ?? this.interval,
        dueAt: dueAt != null ? dueAt() : this.dueAt,
        seenCount: seenCount ?? this.seenCount,
        lapseCount: lapseCount ?? this.lapseCount,
        retiredBy: retiredBy != null ? retiredBy() : this.retiredBy,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => {
        'word_id': wordId,
        'lemma': lemma,
        'state': state.name,
        'interval_min': interval.inMinutes,
        'due_at': dueAt?.millisecondsSinceEpoch,
        'seen_count': seenCount,
        'lapse_count': lapseCount,
        'retired_by': retiredBy?.name,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  static Progress fromJson(Map<String, Object?> j) => Progress(
        wordId: j['word_id'] as int,
        lemma: j['lemma'] as String,
        state: ProgressState.values.byName(j['state'] as String),
        interval: Duration(minutes: j['interval_min'] as int),
        dueAt: j['due_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(j['due_at'] as int),
        seenCount: j['seen_count'] as int,
        lapseCount: j['lapse_count'] as int,
        retiredBy: j['retired_by'] == null
            ? null
            : RetiredBy.values.byName(j['retired_by'] as String),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(j['updated_at'] as int),
      );
}
