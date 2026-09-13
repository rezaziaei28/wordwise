# Phase 3 · Tech stack & architecture

Status: **accepted** (2026-09-12, D-008). Builds on D-003 (Flutter) and the schema
contract in `02-wordlist.md`.

## 1. Toolchain (as of 2026-09-12 on the dev machine)

| | version | note |
|---|---|---|
| Flutter | 3.41.8 stable | Dart 3.11.5 |
| Xcode | 26.6 | iOS builds OK |
| Android SDK | 37 (build-tools 37.0.0), JDK 21 | run `flutter doctor --android-licenses` once |
| Minimum targets | iOS 15, Android 8.0 (API 26) | covers ~99 % of active devices; on-device TTS voices are reliable from here |

## 2. Stack decisions

| Concern | Choice | Why / rejected alternatives |
|---|---|---|
| Language / framework | **Flutter 3.41, Dart 3.11** | D-003. One codebase, first-class gesture/animation for swipe cards. |
| State management | **Riverpod 3** (`flutter_riverpod` 3.3, hand-written providers — see D-009) | Compile-safe providers, trivial to unit-test the domain without widgets, `AsyncNotifier` maps well onto "load queue → swipe → persist". Bloc rejected as heavier ceremony for a small team; `setState`-only rejected because the scheduler must be testable outside widgets. |
| Database | **drift 2.34** over **sqlite3 3.x** for progress; the read-only dictionary is queried with `sqlite3` directly | Typed queries, migrations and reactive `Stream`s for the learner data; `sqlite3` 3.x bundles native libs itself (`sqlite3_flutter_libs` is EOL). The dictionary has a fixed schema and only needs a handful of parameterised reads, so drift adds nothing there. `sqflite` rejected: untyped, no migration framework. |
| Dictionary storage | `words.sqlite` shipped as a **Flutter asset**, copied to app-support dir on first launch, opened read-only | Asset (17.8 MB) keeps the app offline-first (N1). Copy-out is needed because SQLite cannot open an asset in place. |
| Progress storage | separate `progress.sqlite`, drift-managed schema with migrations, opened with `NativeDatabase` on the main isolate | N7: dictionary can be replaced without touching learner data. A background isolate (`drift_flutter` default) cost ~10 s of startup in debug builds and ~14 ms per query; every query here is a handful of rows. |
| Navigation | `go_router` 17 | Declarative, deep-link-ready for later sharing features. Three routes in the MVP; still worth it for consistency. |
| Pronunciation | `flutter_tts` 4.2, `en-US`, IPA text from the DB | D-002. |
| Swipe cards | **own implementation** (`GestureDetector` + `AnimationController` + `Transform`) | ~200 lines; full control of the three-direction semantics, undo animation and pre-rendering the next card. `flutter_card_swiper` / `appinio_swiper` rejected: they model "stack of many cards" and left/right only; bending them costs more than writing ours. |
| Settings | small drift `settings` table (not `shared_preferences`) | One storage, exportable with the rest of the progress (N7). |
| Code generation | `build_runner` for drift only (D-009) | Accepted cost; run via `dart run build_runner build`. |
| Lints | `flutter_lints` + a few stricter rules (`prefer_final_locals`, `unawaited_futures`) | |
| License | **MIT** for code; data stays under its sources' licenses (CC-BY-SA / BSD), attributed in-app | D-004. |

## 3. Architecture

Feature-first layout, strict dependency direction **ui → application → domain ← data**.
The domain (scheduler, queue policy, models) is pure Dart with no Flutter or
drift imports so it is trivially unit-tested.

```
app/
  lib/
    main.dart
    app.dart                      MaterialApp.router, theme, ProviderScope
    router.dart                   go_router routes
    core/                         theme, extensions, constants
    domain/                       pure Dart
      models/    word.dart, sense.dart, progress.dart, grade.dart
      scheduler.dart              grade → next interval/due (pure function)
      queue_policy.dart           which card next (pure function over inputs)
    data/
      dictionary/                 read-only words.sqlite
        dictionary_db.dart        drift database, attaches asset copy
        dictionary_repository.dart
        asset_installer.dart      copy/refresh words.sqlite from assets
      progress/                   learner-owned
        progress_db.dart          drift tables + migrations
        progress_repository.dart
        export.dart               JSON export/import (N7)
    features/
      review/                     the swipe screen
        review_controller.dart    AsyncNotifier: queue, swipe, undo, session stats
        review_screen.dart
        widgets/ word_card.dart, swipe_stack.dart, grade_hint.dart
      words/                      searchable word list, per-word state, retire/unretire
      stats/                      today / totals (F7)
      onboarding/                 calibration (F8)
      settings/
    l10n/                         English only in MVP; strings still externalised
  assets/words.sqlite             built by ../data (git-LFS or release asset — see §8)
  test/                           unit (domain), widget, repository (in-memory sqlite)
  integration_test/               one smoke flow: launch → swipe 3 cards → restart → resumed
```

### Runtime flow

```
launch ─► AssetInstaller.ensure()      copies words.sqlite if missing or meta.built changed
       ─► ProgressDb.open()            runs migrations
       ─► ReviewController.build()     QueuePolicy(dueReviews, nextNewWords, settings) → Queue
swipe  ─► Scheduler.apply(progress, grade, now) → new Progress
       ─► ProgressRepository.record(progress, logEntry)   one transaction
       ─► queue advances; next card was already loaded
undo   ─► ProgressRepository.revert(lastLogEntry)         restores previous row
```

## 4. Data layer

### 4.1 Dictionary (read-only, schema v1 from Phase 2)

Tables `word`, `sense`, `form`, `meta` exactly as built. Accessed through
`DictionaryRepository`:

- `Future<Word> byId(int)`, `Future<List<Word>> byRankRange(int from, int to)`
- `Future<List<Word>> search(String q, {int limit})` — prefix match on
  `lemma` and `form.form` (index exists), so `ran` finds `run`.
- `Future<WordDetail> detail(int id)` — word + senses + forms.

Refresh rule: on launch compare asset `meta.built` (read via a tiny header
query on the asset copy, or a generated `assets/words.version` file — the
latter is cheaper) with the installed copy; replace when different.
Progress references words by `word.id == rank`, which is **stable only within
one dictionary build**. Therefore the progress table stores the `lemma` as
well; on dictionary replacement a one-time remap `lemma → new id` runs, and
lemmas that disappeared are kept in progress but hidden. This is the cost of
D-001/N7 and is worth paying up front.

### 4.2 Progress (learner-owned, drift, migrations from v1)

```sql
CREATE TABLE progress (
  word_id      INTEGER PRIMARY KEY,
  lemma        TEXT NOT NULL,             -- survives dictionary rebuilds
  state        TEXT NOT NULL,             -- 'learning' | 'retired'
  interval_min INTEGER NOT NULL DEFAULT 0,-- minutes; 0 = not yet scheduled
  due_at       INTEGER,                   -- epoch ms, NULL when retired
  seen_count   INTEGER NOT NULL DEFAULT 0,
  lapse_count  INTEGER NOT NULL DEFAULT 0,-- times graded "didn't know"
  retired_by   TEXT,                      -- 'swipe' | 'bulk' | 'list'
  updated_at   INTEGER NOT NULL
);
CREATE INDEX progress_due ON progress(state, due_at);

CREATE TABLE review_log (                 -- append-only; drives undo, stats, later sync
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  word_id       INTEGER NOT NULL,
  lemma         TEXT NOT NULL,
  grade         TEXT NOT NULL,            -- 'know' | 'issues' | 'unknown' | 'unretire' | 'bulk_retire'
  at            INTEGER NOT NULL,
  before_json   TEXT,                     -- previous progress row, for undo
  after_json    TEXT NOT NULL
);

CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);
-- keys: new_per_day (50), tts_rate, tts_voice, show_ipa (1), theme
```

Words with no `progress` row are *new*. Retiring is a row with
`state='retired'`; un-retiring deletes the row (word becomes new again) or,
if it had history, sets it back to learning with `interval_min=0`.

### 4.3 Export / import

`export.dart` writes `{version, exported_at, progress:[…], settings:{…}}` as
JSON to a user-chosen location (share sheet). Import merges by lemma, newest
`updated_at` wins. Also the format later sync will speak.

## 5. Domain

### 5.1 Scheduler (pure function, one constants object)

```dart
class SchedulerConfig {
  final Duration firstUnknown   = const Duration(minutes: 10); // same session
  final Duration unknownRestart = const Duration(days: 1);
  final double   issuesGrowth   = 2.5;
  final Duration issuesMin      = const Duration(days: 1);
  final Duration maxInterval    = const Duration(days: 180);
}

Progress apply(Progress? p, Grade g, DateTime now, SchedulerConfig c):
  know    → state=retired, due=null, retired_by=swipe
  unknown → interval = (p == null || p.interval == 0) ? firstUnknown : unknownRestart
            due = now + interval; lapses++
  issues  → interval = max(issuesMin, p.interval * issuesGrowth) capped at maxInterval
            due = now + interval
  all     → seen_count++, updated_at = now
```

Tunable constants live only here (Phase 1 requirement). A "leech" rule
(lapses ≥ 8 → surface a hint) is a later addition to this same function.

### 5.2 Queue policy (pure function)

Inputs: due reviews (ordered by `due_at`), the next N new words by rank
that have no progress row (found by walking a `next_new_rank` cursor kept in
`settings`, so no cross-database join is needed), `new_per_day`, new words
already introduced today (from `review_log`), session state. Output: an ordered list; reviews first,
then new words up to the remaining daily allowance; never empty while any
new word exists (the cap is soft: when reviews run out and the cap is hit,
the UI offers "continue with new words anyway").

Cards are loaded in pages of 20 and the next page is prefetched at 5 left.

### 5.3 Calibration (F8)

`onboarding` shows 8 sampled words from each of bands 1–5 (40 words). If the
user marks every sample of a band as known, the band is a candidate; the
screen offers "Retire everything up to rank N" for the highest fully-known
contiguous band. Bulk retire writes `progress` rows with `retired_by='bulk'`
in one transaction and a single `review_log` entry (`bulk_retire`, with the
rank range) so it can be undone as a whole from Settings.

## 6. UI

Screens (go_router): `/` review, `/words` list + search, `/words/:id` detail,
`/stats`, `/settings`, `/onboarding` (first launch only).

**Word card.** Front: lemma only (large), band chip, `is_proper`/`is_abbrev`
label. Tap flips (3D `AnimatedBuilder` rotation, 250 ms) to the back: IPA +
speaker button, up to 3 senses (POS, gloss, example in italics), forms line,
rank. Long-press on the back opens the detail route.

**Swipe.** Right = know (green edge glow), left = didn't know (red), down =
had issues (amber). Threshold 35 % of width/height, velocity-aware; below
threshold the card springs back. The card under it is the next queue item,
already built, scaled 0.95. After commit: card flies off, next card scales to
1.0, `ReviewController.swipe(grade)` persists. Undo button (F6) re-enters the
last card with a reverse fly-in.

**Accessibility.** Every swipe has a button equivalent in a bottom row (also
the discoverable path for new users); `Semantics` labels on card faces;
respects `MediaQuery.disableAnimations`. Text scales.

**Theme.** Material 3, light/dark from system, one seed colour. No custom
fonts in the MVP (IPA needs good glyph coverage — system fonts on both
platforms have it; verified during Phase 4 on real devices).

## 7. Testing

- `test/domain/scheduler_test.dart` — table-driven cases for every grade
  path, caps, first-vs-repeat unknown.
- `test/domain/queue_policy_test.dart` — reviews-first, daily cap, soft cap.
- `test/data/*` — repositories against in-memory drift databases; migration
  test that opens a v1 fixture and upgrades.
- Widget tests for the card flip and swipe threshold (using
  `WidgetTester.drag`).
- One `integration_test` smoke flow on a device/emulator.
- CI (GitHub Actions): `flutter analyze`, `flutter test`, plus
  `python -m pytest data/` once the pipeline gets tests; iOS/Android release
  builds only on tags.

## 8. Repository & release

- One repo, `git init` at the project root (not yet done — see §9), layout:
  `design/`, `data/`, `app/`, `.github/workflows/`.
- `app/assets/words.sqlite` is a build product: tracked with **git LFS** so
  clones just work; CI verifies it matches a `make all` rebuild's `meta`
  hash weekly (not on every push — the Kaikki download is 500 MB).
- Versioning: app `x.y.z+build`; dictionary identified by `meta.built`.
- Distribution for the MVP: TestFlight + Android APK/internal track. Store
  listing, screenshots and privacy labels are Phase 4 deliverables.

## 9. Open questions

1. **Bundle id / package name** — proposal `space.jadi.wordwise`
2. **git LFS for the 17.8 MB asset** vs committing it plainly. Plain commits
   of a binary that changes every rebuild bloat history fast; LFS needs the
   user to have `git lfs` installed.
3. **Riverpod code generation** (`@riverpod` + build_runner) vs hand-written
   providers. Generation is the documented default in Riverpod 3; the cost
   is a build step. *Proposal: use generation, same runner drift needs anyway.*
4. **Word-id stability** (§4.1): the remap-by-lemma plan is simple but
   assumes lemma spelling is stable across rebuilds — true unless the US-
   spelling rule changes. Acceptable.
