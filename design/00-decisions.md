# Decision log

Short architecture-decision records. Newest at the bottom.

## D-001 · Meaning is shown as an English learner definition (monolingual)

- **Context:** Intermediate learners; we want one product for every native language.
- **Decision:** Cards show an English definition written for learners plus one
  example sentence. No translations in the MVP.
- **Consequences:** Dictionary data must be permissively licensed and
  learner-readable (see D-004). Translation becomes an optional later feature.

## D-002 · Pronunciation = General American IPA + on-device TTS

- **Context:** Shipping audio for ~40K words is 100+ MB and needs recording or
  licensing; TTS engines on iOS/Android are good enough for single words.
- **Decision:** Each word carries a General American IPA transcription. Tapping
  the speaker icon speaks the word through the platform TTS engine (en-US).
- **Consequences:** Fully offline, near-zero storage. Quality depends on the
  installed voice; we may later add bundled audio for the top N words.

## D-003 · Tech stack is Flutter / Dart

- **Context:** Owner preference and expertise. Requirements: iOS + Android from
  one codebase, smooth swipe-card animation, offline SQLite.
- **Decision:** Flutter. Details (state management, DB layer, packages) are
  decided in Phase 3.
- **Consequences:** Data pipeline (Phase 2) is independent of Flutter and will
  be Python; it produces a SQLite file bundled with the app.

## D-004 · The app and its data are open source

- **Context:** Owner wants an open project.
- **Decision:** Code under a permissive OSS license (exact license chosen in
  Phase 3). Wordlist and dictionary data are built only from sources whose
  licenses allow redistribution (wordfreq, Wiktionary via Kaikki, CMUdict,
  Open English WordNet, …).
- **Consequences:** COCA and commercial dictionary APIs are out. Data provenance
  must be recorded per field so attributions can be shipped with the app.

## D-005 · Proper nouns stay in the list

- **Context:** Frequency lists contain `london`, `obama`, `google`, …
  Excluding them is the common choice for vocabulary apps.
- **Decision:** Keep them. Someone living in the English-speaking world should
  recognise and pronounce these too. They are tagged `proper_noun` so the UI
  can show it and a later setting could hide them.
- **Consequences:** Phase 2 must not filter on capitalisation; it needs a
  proper-noun tag from the dictionary source instead. Pronunciation coverage
  for names must be measured (CMUdict is weaker on names).

## D-006 · Phase 1 open questions resolved with proposed defaults

- Name stays a placeholder ("Wordwise") until later.
- Tail quality (30K–40K band) is decided from Phase 2 measurements.
- Calibration may bulk-retire words below a rank; always reversible.
- Undo covers only the last swipe in the MVP.
- Soft daily cap of 50 new words, configurable, never blocks reviews.

## D-007 · Proper nouns and abbreviations kept only at zipf ≥ 3.3

- **Context:** Keeping every name in the frequency list (D-005 literal) made
  36 % of the last band obscure surnames. See `02-wordlist.md` §4.3.
- **Decision:** `PROPER_MIN_ZIPF = ABBREV_MIN_ZIPF = 3.3` (≈ top 15K). Keeps
  1,356 names (obama, london, houston, rowling) and 293 abbreviations (mr,
  tv, usa, bbc, nba); ~12K obscure ones are excluded and ~10K vocabulary
  words backfill. Contractions fold into their base word; Tatoeba examples
  and multi-word entries are deferred.
- **Consequences:** Phase 2 accepted (2026-09-12). `words.sqlite` schema v1 is
  the contract for Phase 3.

## D-008 · Phase 3 accepted: stack, bundle id, LFS, codegen

- Stack as in `03-tech-stack.md` §2 (Flutter 3.41, Riverpod 3 with code
  generation, drift over sqlite3 3.x, go_router, flutter_tts, MIT).
- Bundle id / Android package: **`space.jadi.wordwise`** (owner's domain
  jadi.space). Placeholder app name "Wordwise" until renamed.
- `app/assets/words.sqlite` tracked with git LFS.
- Progress rows carry the lemma; dictionary rebuilds remap by lemma.
- Repository initialised at the project root at the start of Phase 4.

## D-009 · Riverpod 3 without code generation (amends D-008)

- **Context:** On the installed Dart 3.11.5, no `riverpod_generator` release
  resolves together with `drift_dev` (analyzer `<13` vs `≥13`); the
  releases that would need Dart 3.12 (a Flutter upgrade).
- **Decision:** Hand-written `Notifier`/`AsyncNotifier`/`Provider` classes;
  `build_runner` runs only drift. Revisit when the toolchain moves to
  Dart ≥ 3.12 if the boilerplate becomes a burden.
- **Consequences:** No `@riverpod` annotations; `riverpod_lint` also dropped.

## D-010 · Streak rule: skip ahead, mix back later

- **Context:** Calibration samples 40 words and cannot find an advanced
  learner's real frontier; swiping "know" through thousands of easy words
  is the worst part of the product (baseline §6).
- **Decision:** After 10 consecutive *know* grades on fresh words, the next
  100 unseen words are marked **skipped** (not shown, not counted as known).
  Consecutive jumps without a miss double (100, 200, 400, 800, max 1,000);
  any other grade resets the streak and the growth. Once the learner's
  know-rate on the last 20 fresh words drops below 70 %, skipped words are
  mixed back in — easiest first, one per four new words — and retire on
  *know* or enter learning otherwise. No new jumps happen while mixing.
  A toast announces each jump; the rule can be disabled in Settings.
- **Consequences:** New `ProgressState.skipped`; stats and coverage exclude
  skipped words and report their count; the word list has a *skipped*
  filter. Constants live in `domain/pacing.dart` (`PacingConfig`).
