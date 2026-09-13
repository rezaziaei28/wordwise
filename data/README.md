# data/ — the wordlist pipeline

Builds `build/words.sqlite`, the dictionary bundled with the app. Design and
measurements: [`../design/02-wordlist.md`](../design/02-wordlist.md).

```sh
make venv download   # once: Python venv + ~500 MB Wiktionary extract + CMUdict
make all             # ~2 min: frequency → lexicon → lemmas → sqlite → report
```

Scripts in `pipeline/` run in order and each writes one artefact to `build/`:

| script | output | what |
|---|---|---|
| `s01_frequency.py` | `01_frequency.tsv` | top 300K tokens from wordfreq with frequency |
| `s02_lexicon.py` | `02_lexicon.jsonl`, `02_forms.tsv`, `02_us_spelling.tsv` | Wiktionary (Kaikki) → lemma entries, form links, British→US spellings |
| `s03_lemmatize.py` | `03_lemmas.tsv`, `03_dropped.tsv` | tokens → lemmas, aggregate, threshold names/abbreviations, rank, cut at 40K |
| `s04_build_sqlite.py` | `words.sqlite` | senses, IPA (Wiktionary, else CMUdict), forms |
| `s05_report.py` | `05_report.md` | per-band quality measurements |

Tunables live in `pipeline/common.py` (`TARGET_SIZE`, `PROPER_MIN_ZIPF`,
`ABBREV_MIN_ZIPF`).

Sources and licenses: wordfreq (data CC-BY-SA 4.0), Wiktionary via kaikki.org
(CC-BY-SA 3.0 / GFDL), CMUdict (BSD-2). These are recorded in the `meta`
table of the built database.
