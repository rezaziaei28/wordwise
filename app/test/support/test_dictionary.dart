import 'package:sqlite3/sqlite3.dart';
import 'package:wordwise/data/dictionary/dictionary_repository.dart';

/// An in-memory dictionary with the v1 schema and [n] words `w1..wn`.
DictionaryRepository testDictionary({int n = 100}) {
  final db = sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE word (id INTEGER PRIMARY KEY, lemma TEXT NOT NULL UNIQUE, rank INTEGER NOT NULL,
      band INTEGER NOT NULL, zipf REAL NOT NULL, ipa TEXT, ipa_source TEXT,
      is_proper INTEGER NOT NULL DEFAULT 0, is_abbrev INTEGER NOT NULL DEFAULT 0, pos TEXT NOT NULL);
    CREATE TABLE sense (id INTEGER PRIMARY KEY, word_id INTEGER NOT NULL, ord INTEGER NOT NULL,
      pos TEXT NOT NULL, gloss TEXT NOT NULL, example TEXT);
    CREATE TABLE form (word_id INTEGER NOT NULL, form TEXT NOT NULL, PRIMARY KEY (word_id, form));
    CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);
    INSERT INTO meta VALUES ('built', 'test');
  ''');
  final ins = db.prepare('INSERT INTO word VALUES (?,?,?,?,?,?,?,?,?,?)');
  final sense = db.prepare('INSERT INTO sense (word_id, ord, pos, gloss, example) VALUES (?,?,?,?,?)');
  final form = db.prepare('INSERT INTO form VALUES (?,?)');
  for (var i = 1; i <= n; i++) {
    ins.execute([i, 'w$i', i, (i - 1) ~/ 1000 + 1, 6.0 - i / 100, '/w$i/', 'wiktionary', i % 10 == 0 ? 1 : 0, 0, 'noun']);
    sense.execute([i, 1, 'noun', 'gloss of w$i', 'Example with w$i.']);
    form.execute([i, 'w${i}s']);
  }
  ins.close();
  sense.close();
  form.close();
  return DictionaryRepository(db);
}
