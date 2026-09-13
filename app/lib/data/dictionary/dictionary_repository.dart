import 'package:sqlite3/sqlite3.dart';

import '../../domain/models.dart';

/// Read-only access to the bundled dictionary (schema v1, design/02 §3).
class DictionaryRepository {
  DictionaryRepository(this._db);

  factory DictionaryRepository.open(String path) =>
      DictionaryRepository(sqlite3.open(path, mode: OpenMode.readOnly));

  final Database _db;

  static const _wordColumns = 'id, lemma, band, zipf, ipa, is_proper, is_abbrev, pos';

  Word _word(Row r) => Word(
        id: r['id'] as int,
        lemma: r['lemma'] as String,
        band: r['band'] as int,
        zipf: (r['zipf'] as num).toDouble(),
        ipa: r['ipa'] as String?,
        isProper: (r['is_proper'] as int) == 1,
        isAbbrev: (r['is_abbrev'] as int) == 1,
        pos: (r['pos'] as String).split(',').where((s) => s.isNotEmpty).toList(),
      );

  int get count => _db.select('SELECT count(*) AS n FROM word').first['n'] as int;

  String get built => _db.select("SELECT value FROM meta WHERE key='built'").first['value'] as String;

  Word? byId(int id) {
    final rows = _db.select('SELECT $_wordColumns FROM word WHERE id = ?', [id]);
    return rows.isEmpty ? null : _word(rows.first);
  }

  List<Word> byIds(Iterable<int> ids) {
    final list = ids.toList();
    if (list.isEmpty) return const [];
    final marks = List.filled(list.length, '?').join(',');
    final byId = {for (final r in _db.select('SELECT $_wordColumns FROM word WHERE id IN ($marks)', list)) r['id'] as int: _word(r)};
    return [for (final id in list) if (byId[id] != null) byId[id]!];
  }

  Word? byLemma(String lemma) {
    final rows = _db.select('SELECT $_wordColumns FROM word WHERE lemma = ?', [lemma]);
    return rows.isEmpty ? null : _word(rows.first);
  }

  /// Words with `rank > after`, in rank order.
  List<Word> afterRank(int after, {int limit = 50}) =>
      _db.select('SELECT $_wordColumns FROM word WHERE rank > ? ORDER BY rank LIMIT ?', [after, limit]).map(_word).toList();

  List<Word> page({required int offset, required int limit}) =>
      _db.select('SELECT $_wordColumns FROM word ORDER BY rank LIMIT ? OFFSET ?', [limit, offset]).map(_word).toList();

  /// Prefix search on lemma and inflected forms (`ran` finds `run`).
  List<Word> search(String query, {int limit = 50}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final like = '${q.replaceAll('%', '').replaceAll('_', '')}%';
    return _db.select('''
      SELECT DISTINCT $_wordColumns FROM word
      WHERE id IN (
        SELECT id FROM word WHERE lemma LIKE ?
        UNION SELECT word_id FROM form WHERE form LIKE ?
      )
      ORDER BY (lemma = ?) DESC, rank
      LIMIT ?
    ''', [like, like, q, limit]).map(_word).toList();
  }

  /// `n` random words from a band, for calibration.
  List<Word> sampleBand(int band, int n) =>
      _db.select('SELECT $_wordColumns FROM word WHERE band = ? ORDER BY random() LIMIT ?', [band, n]).map(_word).toList();

  WordDetail detail(int id) {
    final word = byId(id);
    if (word == null) throw StateError('no word $id');
    final senses = _db
        .select('SELECT ord, pos, gloss, example FROM sense WHERE word_id = ? ORDER BY ord', [id])
        .map((r) => Sense(ord: r['ord'] as int, pos: r['pos'] as String, gloss: r['gloss'] as String, example: r['example'] as String?))
        .toList();
    final forms = _db.select('SELECT form FROM form WHERE word_id = ? ORDER BY form', [id]).map((r) => r['form'] as String).toList();
    return WordDetail(word: word, senses: senses, forms: forms);
  }

  void close() => _db.close();
}
