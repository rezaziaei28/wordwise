# Phase 1 · Baseline understanding

Status: **accepted** (2026-09-12). Open questions resolved in `00-decisions.md` D-005/D-006.
Source: `initial_prompt.md` plus the Phase 1 Q&A (recorded in `00-decisions.md`).

## 1. The idea in one paragraph

A native speaker reading a novel or a newspaper knows essentially every word on
the page, and how it sounds. An intermediate learner does not, and doesn't know
*which* words they are missing. This app takes the ~40,000 most frequent English
words (as measured across books, news, subtitles and social media), and walks
the learner through them, most frequent first, as swipeable flashcards. The
learner's job is honest self-assessment: *I know this — I sort of know this —
I don't know this.* The app's job is to never waste time on known words, and to
keep bringing back the others until they stick — meaning **and** pronunciation.

Working name: **Wordwise** (placeholder; not a decision).

## 2. Who it is for

**Primary persona — "the honest adult learner"**

- Non-native, intermediate (roughly B1–B2). Can read news with effort; knows
  the top ~3–5K words well, patchy from there.
- Adult, self-motivated, studying on their own time (commute, bed, coffee).
- Cares about *pronunciation*, not just recognition — has been embarrassed by
  saying a word they had only read.
- Any native language (D-001: monolingual definitions).

**Explicit assumption (from the prompt):** the user is trying to learn, not to
game the app. We therefore do *not* test them (no quizzes, no multiple choice
in the MVP). Self-grading is trusted.

**Not designed for (non-goals for now):** beginners (A1–A2), children, exam
prep (IELTS/TOEFL word lists), classroom use, teachers.

## 3. The core loop

```
 ┌────────────────────────────────────────────────┐
 │  Card front: the word                          │
 │      "ubiquitous"                              │
 │                                                │
 │  (tap card) ──► flips to reveal:               │
 │      /juːˈbɪkwɪtəs/   [🔊]                      │
 │      adj. present or found everywhere          │
 │      "Smartphones have become ubiquitous."     │
 │      rank #9,412 · adjective                   │
 └────────────────────────────────────────────────┘
        ◄── swipe          swipe ──►         swipe ▼
     "Didn't know"        "Know it"        "Had issues"
     repeat often       never show again   repeat later
```

The rule is: **one word, one card, three outcomes.** The learner may look at
the back before deciding, and is expected to. The card front deliberately shows
only the word so the learner first tests recall of meaning *and* pronunciation
in their head, then flips to check, then grades.

### Swipe semantics (from the prompt, made precise)

| Swipe | Meaning | What the app does |
|-------|---------|-------------------|
| **Know it** | "I'm sure I know the meaning and pronunciation." | Word is *retired*. Never shown again unless the user un-retires it from the word list. |
| **Had issues** | "I sort of knew it — wrong pronunciation, or I hesitated on the meaning." | Word is scheduled again after a *moderate* interval that grows each time it is graded this way. |
| **Didn't know** | "New to me / I was wrong." | Word is scheduled again *soon* and interval resets to the shortest step. |

Swipe direction mapping (right = know, left = didn't know, down = had issues)
is a UI detail for Phase 4; the three-outcome model is the requirement.

### Ordering: what card comes next?

Two queues, merged:

1. **Review queue** — words previously graded *Had issues* or *Didn't know*
   whose due time has passed. These always come first.
2. **New-word queue** — words never seen, in **frequency-rank order** (most
   common first). This is the heart of the product: the learner meets words in
   the order in which they will actually encounter them in the wild.

Because an intermediate learner will swipe "Know it" on the first several
thousand words, the app must make that fast: calibration at first launch
(§6) and, during review, the **streak rule** (D-010) — ten *know* grades in
a row skip the next 100+ unseen words, which are mixed back in later once
the learner starts missing words.

### Scheduling (spaced repetition, simplified)

We deliberately do **not** copy Anki's SM-2 wholesale. Three-outcome grading
plus a "retire" action gives a simpler model:

- Each active word has `interval` (days) and `due` (timestamp).
- *Didn't know* → `interval = 1 day` (first time: ~10 minutes, i.e. later in the
  same session), `due = now + interval`.
- *Had issues* → `interval = max(1, interval) × 2.5`, `due = now + interval`.
- *Know it* → retired. A word graded *Know it* right after a *Didn't know* is
  still retired — we trust the adult (D: honesty assumption).
- Optional later: a "leech" rule (word failed N times → shown with extra help).

Exact constants are tuned in Phase 4 and should live in one place so they can
be changed without a data migration.

## 4. What is on a card (data requirements)

Per word, the app needs:

| Field | Required | Source (Phase 2 decides) |
|-------|----------|--------------------------|
| headword (lemma) | yes | frequency list |
| frequency rank | yes | frequency list |
| part(s) of speech | yes | dictionary |
| IPA (General American) | yes | CMUdict / Wiktionary |
| learner-friendly definition, 1–3 senses | yes | Wiktionary / Open English WordNet |
| one example sentence per shown sense | strongly wanted | Wiktionary / Tatoeba |
| audio | no — TTS on device (D-002) | — |
| inflected forms (run → runs, ran, running) | wanted | Wiktionary / lemmatizer |
| frequency band / "how important" text | later (stats phase) | derived |

A *word* is a **lemma**, not a surface form: `run` is one card, not four.
Multi-word entries (`give up`, `as well as`) are out of the MVP list but the
schema must not preclude them. Proper nouns (`london`, `obama`) are **kept**
and tagged (D-005).

## 5. Requirements

### Functional (MVP-level, detailed in Phase 4)

- F1. Show one card at a time; tap to flip; three swipe outcomes.
- F2. Play pronunciation via TTS; show IPA.
- F3. Persist every grade locally; resume where the user left off.
- F4. New words are served in frequency order; due reviews are served first.
- F5. A word list screen: search any word, see its state, retire / un-retire it.
- F6. Undo the last swipe (mis-swipes are common).
- F7. Basic session stats: cards done today, retired total, words in review.
- F8. Onboarding "calibration" to skip past known easy words quickly (see §6).

### Non-functional

- N1. **Offline-first.** The full wordlist ships inside the app; no network is
  needed for anything in the MVP.
- N2. **Fast.** Card flip and swipe must be 60 fps; next card pre-loaded.
- N3. **Small.** Target install size < 60 MB including data (40K entries with
  definitions + IPA + examples in SQLite ≈ 20–30 MB compressed; verify in Phase 2).
- N4. **Private.** No account, no analytics, in the MVP. Sync/sharing is opt-in
  and later.
- N5. **Open.** Code and data under permissive licenses (D-004); all data
  sources attributed in-app.
- N6. iOS and Android from one Flutter codebase (D-003).
- N7. Learner data must survive app updates (schema versioning and migrations
  from day one) and be exportable (JSON) so the user owns their progress.

## 6. Key design tensions (thought through)

**40K words is a lot.** Rough coverage numbers for English running text: top 2K
lemmas ≈ 80 %, top 5K ≈ 90 %, top 10K ≈ 95 %, top 20K ≈ 98 %. Beyond ~25K the
list is dominated by rare, technical and proper-noun-ish items. We keep the
40K target from the prompt, but (a) the list is built in **frequency bands**
(1–1K, 1–2K, … ) so the app can present progress meaningfully, and (b) Phase 2
must measure how clean the tail is — it may be that "40K" becomes "35K clean
lemmas". This is flagged as an open question, not silently changed.

**Intermediate learners know the first few thousand words.** Swiping "Know it"
5,000 times is a terrible first hour. Mitigations, in order of preference:
1. *Calibration on first launch:* show ~10 sample words from each band; if the
   user knows all samples from bands 1–4, offer to retire everything below
   band 5 in bulk (reversible from the word list).
2. Let the user pick a starting rank manually ("start at word #3,000").
3. Make "Know it" the cheapest gesture and show a running streak so the fast
   phase still feels productive.

**Trusting self-grading vs. helping honesty.** We don't test, but we can help:
the front shows only the word, so the user must recall before revealing. A
future "say it" feature (speech recognition scoring) is compatible with this.

**Meaning vs. pronunciation are graded together.** The prompt treats "wrong
pronunciation" as *Had issues*. We keep a single grade to keep the swipe model
simple; per-dimension grading is noted as a possible later refinement.

**Polysemy.** `run` has dozens of senses. The card shows the 1–3 most common
senses only; the full entry is available on a details screen. Which senses are
"most common" is a Phase 2 data question (Wiktionary sense order is a
reasonable proxy).

## 7. Out of scope for the MVP (planned later, per the prompt)

- Usage statistics beyond F7; "how important is this word" explanations.
- Server sync, sharing progress, crowd difficulty of words.
- Translations, multiple accents, bundled human audio.
- Speech-recognition pronunciation check.
- Multi-word expressions, phrasal verbs as separate cards.

## 8. Phase plan

| Phase | Deliverable | Exit criterion |
|-------|-------------|----------------|
| 1 (this) | Baseline understanding | Owner accepts this document |
| 2 | `02-wordlist.md` + reproducible pipeline (`data/`) producing `words.sqlite` | 40K-ish lemma list with rank, POS, IPA, definitions, examples; license audit passed; size measured |
| 3 | `03-tech-stack.md` | Flutter architecture, packages, DB layer, project layout, CI, license chosen |
| 4 | `04-mvp.md` + working app | F1–F8 on a real iPhone and Android device |
| 5+ | stats, sync, sharing | later |

## 9. Open questions (resolved — see D-005, D-006)

1. **Name.** "Wordwise" is a placeholder — any preference?
2. **Tail quality.** If the 30K–40K band turns out to be mostly junk
   (abbreviations, names, OCR noise), do we stop at a smaller clean number or
   pad with a second source? *Proposal: decide from Phase 2 measurements.*
3. **Proper nouns.** Exclude entirely (`london`, `obama`)? Include them. The user wants to know it if it is a common word.
   → **Overruled: keep them** (D-005). A learner living in the English-speaking
   world should know them too; they are tagged so the UI can label them.
4. **Calibration.** Is the bulk "retire everything below rank N" acceptable, or
   should every word be individually swiped? *Proposal: allow bulk, reversible.*
5. **Undo depth.** Only the last swipe, or a full session history? *Proposal:
   last swipe in MVP.*
6. **Daily limits.** Anki-style "N new words per day" cap, or unlimited?
   *Proposal: soft default of 50 new/day, configurable, never blocks reviews.*
