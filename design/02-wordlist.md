# Phase 2 · The wordlist

Status: **accepted** (2026-09-12, D-007). Pipeline runs end to end (`data/`, `make all`);
§4 holds the measurements and §5 the decisions still needed.

## 1. Goal

Produce one file, `data/build/words.sqlite`, containing the ~40,000 most useful
English lemmas with, per lemma: rank, frequency, part(s) of speech, General
American IPA, 1–3 learner-readable senses with example sentences, inflected
forms, and a proper-noun flag. Everything must be rebuildable from public,
permissively licensed sources by one command.

## 2. Source selection

Candidates were judged on license (D-004), coverage of the ~40K range, and
whether they are *already lemmatised*.

| Need | Source | License | Why |
|------|--------|---------|-----|
| Frequency | **wordfreq 3.x** (`large` list, `en`) | MIT code; data CC-BY-SA 4.0 | Blends Wikipedia, subtitles (OpenSubtitles), news (NewsCrawl), books (Google Books), Twitter/Reddit → matches the prompt's "books, news, social media" almost exactly. Ships ~200K+ English tokens. |
| Lemmatisation & dictionary | **Wiktionary via Kaikki** (`kaikki.org-dictionary-English.jsonl`) | CC-BY-SA 3.0 / GFDL | One JSON object per entry with POS, senses/glosses, examples, `form_of` links, `forms[]`, IPA per accent, and `proper-noun` POS. Solves lemmatisation, definitions, examples and most IPA from one file. |
| IPA fallback | **CMUdict** (cmusphinx) | BSD-2 | ARPAbet for ~135K words; converted to IPA when Wiktionary has no US transcription. |
| Definitions fallback | Open English WordNet 2024 | CC-BY 4.0 | Only if Wiktionary glosses are missing/too terse for a lemma. Deferred until measured. |

Rejected: COCA (paid), Google Books Ngrams alone (books only, no lemmas),
SUBTLEX (research-only license), any commercial dictionary API (license, and
violates offline-first).

## 3. Pipeline

```
raw/                         build/
 kaikki-en.jsonl.gz ─┐        01 frequency.tsv        (wordfreq tokens, freq)
 cmudict.dict       ─┤   ─►   02 lexicon.jsonl        (Kaikki: lemmas, forms, senses, IPA)
                     │   ─►   03 lemmas.tsv           (token→lemma, aggregated, ranked)
                     └─  ─►   04 words.sqlite         (final)
                              05 report.md            (measurements)
```

Scripts live in `data/pipeline/`, numbered, each idempotent, each writing one
artefact to `data/build/`. `make all` (or `python -m pipeline`) runs them in
order. `raw/` and `build/` are git-ignored; only `words.sqlite` is checked in
via LFS or attached to releases (decided in Phase 3).

### Step 1 — frequency tokens

`wordfreq.top_n_list('en', 300_000, wordlist='large')` with
`word_frequency()` per token. Keep tokens matching `^[a-z][a-z'\-]*$` (wordfreq
lower-cases and strips most punctuation already). Single letters other than
`a`/`i` are dropped.

### Step 2 — lexicon from Kaikki

Stream the JSONL once (1.49 M entries, 36 s). For every `lang_code == "en"`
entry whose word is a single token:

- **Lemma entries** — POS in {noun, verb, adj, adv, name, pron, prep, conj,
  det, article, num, intj, particle, contraction, abbrev, postp} with at least
  one sense that is not a `form_of`/`alt_of` link. Record word, POS, whether
  POS is `name` (proper noun), senses (gloss, quality tags, one example), IPA
  tagged `US`/`General-American` (else untagged IPA).
- **Form links** (`surface → lemma`) from three places, each filtered:
  1. `form_of`/`alt_of` senses, **unless** tagged misspelling / dialectal /
     obsolete / archaic / rare / eye-dialect / slang / Internet / abbreviation
     … — these tags are what let `teh→the`, `is→us` (Geordie) and
     `zee→the` into an earlier build.
  2. Glosses of the shape "*Commonwealth and Ireland standard spelling of
     color*" that Kaikki did not parse into a link (regex anchored at the end
     of the gloss — an unanchored version matched "*a diminutive form of
     **the** male given name Vincent*").
  3. `forms[]` tables, only entries tagged as inflections (plural, past,
     participle, comparative, superlative, third-person), only on
     noun/verb/adj/adv entries, never on single-letter lemmas (the letter *i*
     lists *is* as its plural).
  Contractions (`I'm`, `don't`) link to their first word.
- **US spellings** — `humor` "US spelling of humour", and `humour` listing
  `humor` as an `alternative, US` form, both yield `humour → humor`.

Kaikki keys are case-sensitive (`Obama`, `March`/`march`); everything is
lower-cased and entries merge under one lemma.

### Step 3 — lemmatise and rank

A lemma is *strong* if it has a non-proper-noun entry with at least one
untagged sense. `centre` (a French region + "alt of center") and `theatre`
(one *rare* sense) are lemmas but not strong; this distinction is what lets
British spellings fold into American headwords.

For each frequency token:

1. Follow form links until a strong lemma is reached
   (`recognised → recognise → recognize`, `centres → centre → center`),
   preferring at each hop the candidate simplemma agrees with (so `is → be`,
   not `is → i`).
2. If the token is itself a strong lemma (`running`, `used`, `could`, `news`),
   fold only when **simplemma independently agrees** (`running→run` yes,
   `could→could` stays, `news` stays). Otherwise follow the link.
3. No link: try simplemma's lemma, then a stripped possessive (`world's`,
   `obama's`), each resolved as in 1.
4. Else the token is a lemma if Wiktionary has it, else **dropped**.

Frequency of a lemma = sum over everything folded into it. A British lemma
whose US spelling is also a lemma (`favourite`/`favorite`) merges into the US
one. Headword = US spelling; the British form is kept as a *form*.

Then, **before** cutting (D-007, tightened by D-011):

- *person names* (given names; surnames without Wikipedia + place) are
  dropped regardless of frequency unless strongly notable;
- *proper nouns* below `PROPER_MIN_ZIPF` (4.0 ≈ rank 5,000) and
  *abbreviations* below `ABBREV_MIN_ZIPF` (4.5 ≈ rank 2,000) are excluded;
- *one- and two-letter lemmas* outside `SHORT_WORDS` (and not all-caps
  abbreviations), Roman numerals and URL debris are dropped;

so common vocabulary backfills their slots — see §4.3 and §5. Rank, cut at
40,000, band = ⌈rank / 1000⌉.

Consequences accepted: `united → unite`, `glasses → glass`, `better → good`
(all listed as forms on the base card). `frank`, `peter`, `bernard` stay
because they also have common-noun/verb senses — they are not flagged proper.

### Step 4 — enrich and build SQLite

- IPA: Wiktionary transcriptions are ranked (GA strong form → untagged →
  RP → regional; weak/unstressed and vowel-reduced forms last). The
  *primary* Wiktionary entry is used only when its best transcription is
  GA-tagged and none of those flags apply; otherwise **CMUdict** (uniformly
  General American; ARPAbet→IPA with stress marks, none on monosyllables);
  otherwise whatever Wiktionary has. Wiktionary's accent tagging turned out
  too inconsistent to trust blindly (`on` has no plain GA entry; `you`'s only
  GA entry was the weak form /jə/).
- Senses: up to 3, in Wiktionary page order (primary etymology first, proper
  noun entries last), untagged senses before obsolete/archaic/rare/vulgar
  ones; if the word has a second POS, the third slot is given to it. One
  example per sense (20–160 chars).
- Forms: every surface form that folded into the lemma, minus possessives.
- `is_proper`: every entry capitalised, a `name` entry, and name senses ≥
  untagged common senses (david, chicago, russia). `is_abbrev`: every sense
  is "Abbreviation/Initialism/… of", or every entry is ALL CAPS (nfl, dna).

### Schema (v1)

```sql
CREATE TABLE word (
  id          INTEGER PRIMARY KEY,      -- == rank
  lemma       TEXT NOT NULL UNIQUE,
  rank        INTEGER NOT NULL,
  band        INTEGER NOT NULL,         -- rank/1000 rounded up
  zipf        REAL NOT NULL,            -- log10 freq per billion, from wordfreq
  ipa         TEXT,                     -- General American
  ipa_source  TEXT,                     -- 'wiktionary' | 'cmudict' | NULL
  is_proper   INTEGER NOT NULL DEFAULT 0,
  is_abbrev   INTEGER NOT NULL DEFAULT 0,
  pos         TEXT NOT NULL             -- comma-separated, Wiktionary order
);
CREATE TABLE sense (
  id        INTEGER PRIMARY KEY,
  word_id   INTEGER NOT NULL REFERENCES word(id),
  ord       INTEGER NOT NULL,           -- 1..3
  pos       TEXT NOT NULL,
  gloss     TEXT NOT NULL,
  example   TEXT
);
CREATE TABLE form (
  word_id   INTEGER NOT NULL REFERENCES word(id),
  form      TEXT NOT NULL,
  PRIMARY KEY (word_id, form)
);
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);  -- schema_version, build date, source versions, licenses
```

Learner progress lives in a *separate* database owned by the app (Phase 3), so
`words.sqlite` can be replaced on update without touching user data.

## 4. Measurements

From `data/build/05_report.md`, build of 2026-09-12 (wordfreq 3.1.1,
Kaikki dump of September 2026, thresholds at 3.3).

### 4.1 Size and coverage

- 288,815 usable wordfreq tokens → 132,237 lemmas found → **40,000 kept**.
- `words.sqlite`: **17.8 MB** uncompressed (well under the N3 budget).
- 92,586 tokens dropped for not being in Wiktionary. The most frequent are
  Roman numerals, g-dropped spellings (`doin`, `lookin`), unapostrophised
  misspellings (`doesnt`, `wasnt`), foreign words (`von`, `sur`, `deutsche`)
  and brands (`itunes`, `verizon`, `spotify`). Nothing a learner needs.
- Zipf at the cut: **2.11** (≈ 130 occurrences per billion words).
- Cumulative frequency mass inside the list: top 1K = 77.5 %, 2K = 85.2 %,
  5K = 92.9 %, 10K = 96.6 %, 20K = 98.8 %, 30K = 99.6 %. Ranks 20K–40K add
  about 1.2 % of running text between them.

### 4.2 Quality by band

| band | zipf | proper % | IPA % | senses w/ example | sample |
|---|---|---|---|---|---|
| 2 | 5.05–4.67 | 2 | 100 | 68 % | senate, male, status, strange, mode, chairman, label, assist, affair |
| 6 | 4.10–3.97 | 7 | 98 | 47 % | cone, clone, vanish, cocaine, subtle, nod, fridge, cosmetic, inequality |
| 10 | 3.67–3.60 | 12 | 96 | 39 % | sabbath, famine, vibrant, hamas, irresponsible, naples, excavation |
| 14 | 3.39–3.33 | 15 | 94 | 39 % | tramp, unaffected, skillful, arid, tulip, saline, sturgeon, hemorrhage |
| 18 | 3.15–3.09 | 0 | 95 | 38 % | rump, infidel, burlesque, lexicon, fastball, chum, haiku, epoxy, normative |
| 22 | 2.92–2.87 | 0 | 94 | 37 % | follow-up, larval, brainstorm, acumen, applicability, dapper, cliffhanger |
| 26 | 2.72–2.67 | 0 | 87 | 35 % | obliquely, bothersome, logarithm, tubby, delimit, clairvoyant, fandango |
| 30 | 2.54–2.50 | 0 | 80 | 33 % | isotropic, nihilistic, antsy, godliness, impeller, sugarcoat |
| 34 | 2.37–2.33 | 0 | 75 | 33 % | fetid, overground, copyist, joyless, chokehold, satsuma, redraft |
| 38 | 2.22–2.18 | 0 | 67 | 30 % | palpably, radiographer, trailblazing, wrathful, lionfish, gentlewoman |

Readings:

- **Bands 1–15 are clean** general vocabulary with a rising share of
  well-known names (`houston`, `colorado`, `romney`, `lennon`).
- **Bands 16–40** are rare-but-real words. They are not junk, but they are
  the "1.2 % of text" tail: a learner who knows bands 1–20 reads at native
  coverage. This is the honest answer to the prompt's "~40K": the list is
  40K, and the app should present bands 20+ as *depth*, not as a requirement.
- IPA coverage is 100 % in the first 5K, 96 % at 10K, 67 % at 40K
  (18.3K from Wiktionary, 17.5K from CMUdict, 4.2K none). Missing entries
  are rare derivations CMUdict does not have; TTS still speaks them.
- **Examples are the weak spot**: 76 % of senses in band 1 have one, ~30 % in
  the tail. Tatoeba (CC-BY) is the obvious fill — noted for a later
  iteration, not a blocker for the MVP.

### 4.3 Effect of the name / abbreviation rules

| | threshold 0 (keep all, D-005 literal) | 3.3 (D-007) | D-011 (built) |
|---|---|---|---|
| proper nouns in list | 8,096 (`lundgren`, `souter`) | 1,356 (`obama`, `taylor`, `derek`) | 161 (`london`, `germany`, `obama`, `january`) |
| abbreviations in list | 1,818 (`hss`, `spl`) | 293 (`mr`, `nba`, `crm`) | 8 (`tv`, `etc`, `usa`, `eu`, `bbc`, `nfl`, `ft`, `ceo`) |
| one/two-letter lemmas | — | 166 in the first 6K (`ez`, `de`, `st`, `al`, `ll`) | 32 in total, all real words |
| zipf at rank 40,000 | 2.41 | 2.11 | 1.99 |

Given names are gone as a class (`david`, `james`, `sarah` — 11,851
person names excluded); places, months, nationalities and notable people
with a Wikipedia-linked place sense stay. Names that also have a common
meaning (`frank`, `mark`, `john`) are unaffected by any of this.

## 5. Open questions

1. **Proper-noun / abbreviation threshold** (refines D-005). The built list
   keeps names and abbreviations only at zipf ≥ 3.3 (≈ top 15K). *Proposal:
   accept 3.3.* Alternatives: 0 (keep every name the frequency list has —
   36 % of the last band becomes surnames) or a higher value like 3.6 (top
   10K; drops `romney`, `lennon`, `naples`).
2. **Contractions.** `don't`, `i'm`, `you're` fold into `do`, `i`, `you` as
   forms. `don't` still surfaces as its own card in band 1 because Wiktionary
   gives it independent senses. *Proposal: accept as is.*
3. **Examples for the tail** — add Tatoeba in a later data iteration.
4. Multi-word entries: excluded (tokens are single words); revisit later.
