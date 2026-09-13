# Phase 4 · MVP specification

Status: **M1–M4 built; M5 (device pass) pending.** Derives acceptance criteria from `01-baseline.md`
§5 (F1–F8, N1–N7) and the architecture in `03-tech-stack.md`. The MVP is
done when every criterion below passes on one physical iPhone and one
Android device.

## 1. Scope

**In:** review screen with swipe cards, TTS + IPA, local persistence and
resume, frequency-ordered new words with due reviews first, word list with
search and retire/un-retire, undo last swipe, session/total stats, first-launch
calibration, settings (new words per day, IPA on/off, TTS rate), progress
export/import, attribution screen.

**Out (per baseline §7):** accounts, sync, sharing, translations, human audio,
speech recognition, multi-word entries, notifications, widgets, iPad/tablet
layouts (works, not optimised), localisation of the UI.

## 2. Screens and acceptance criteria

### 2.1 Review (`/`) — F1, F2, F4, F6, F7

- A1. On launch (after onboarding) the first card is visible within 1 s on a
  2020 mid-range phone; the card shows only the lemma, its band chip and a
  proper-noun/abbreviation label when applicable.
- A2. Tap flips the card to reveal IPA, speaker button, ≤ 3 senses with POS
  and example, forms line and rank. Tap again flips back.
- A3. Speaker button (and the IPA text) speaks the lemma via `en-US` TTS;
  works in airplane mode.
- A4. Swipe right = *know*, left = *didn't know*, down = *had issues*;
  releasing below the threshold springs back; edge glow colours indicate the
  pending grade during the drag. Three labelled buttons below the card do
  the same.
- A5. After a swipe the next card is already rendered underneath; no blank
  frame. 60 fps on the drag (verified with the performance overlay).
- A6. Undo restores the previous card and its prior progress row; one level.
- A7. Header shows today's count (done / new introduced) and the review
  backlog; the numbers match `review_log`.
- A8. Order: due reviews (by `due_at`) before new words (by rank); a word
  graded *didn't know* the first time comes back within the same session
  after ~10 minutes or 20 cards, whichever first (the scheduler's
  `firstUnknown`); *know* never returns.
- A9. Soft cap: when today's new-word allowance is spent and no review is
  due, the screen shows "Daily goal reached" with a "Keep going" button.
- A10. Killing and relaunching the app resumes with the same next card.
- A11. Streak rule (D-010): the header shows the streak; the tenth *know* in
  a row on fresh words jumps ahead (toast names the count and new rank);
  jumps grow 100→200→400→800→1000 and reset on a miss; skipped words return
  once the know-rate on the last 20 fresh words is below 70 %, carry a
  "skipped earlier" chip, and retire on *know*. Off switch in Settings.

### 2.2 Word list (`/words`, `/words/:id`) — F5

- B1. Scrollable list of all 40,000 words, rank order, virtualised (no
  jank); each row: lemma, band, state icon (new / learning-due / learning /
  retired).
- B2. Search box: prefix on lemma and inflected forms (`ran` → `run`), results
  under 100 ms for 3+ letters.
- B3. Filter chips: all / learning / retired / new.
- B4. Detail: full card back plus history (last 10 log entries) and a
  Retire / Un-retire toggle that writes `retired_by='list'`.

### 2.3 Onboarding (`/onboarding`) — F8

- C1. Shown once (setting `onboarded=1`). Explains the three swipes in one
  screen with a demo card.
- C2. Calibration: 8 sampled words from each of bands 1–5, presented as the
  real card UI; then a summary "You knew all of bands 1–3 → retire words
  1–3,000?" with Yes / No. Yes bulk-retires (`retired_by='bulk'`) in one
  transaction and one log entry. Skippable.
- C3. Settings has "Undo calibration" that reverses the bulk entry.

### 2.4 Stats (`/stats`) — F7

- D1. Today: cards reviewed, new introduced, known / issues / unknown split.
- D2. Totals: retired, learning, due now, highest band touched; a 40-cell
  band strip showing % retired per band.

### 2.5 Settings (`/settings`)

- E1. New words per day (10–200, default 50), show IPA, TTS rate, theme.
- E2. Export progress (share sheet, JSON), Import (file picker, merge by
  lemma, newest wins), Undo calibration.
- E3. About: app version, dictionary `meta.built`, licenses of wordfreq /
  Wiktionary / CMUdict and Flutter's package licenses.

### 2.6 Non-functional checks

- N1 offline: all criteria pass in airplane mode.
- N3 size: release APK ≤ 60 MB, iOS app ≤ 80 MB installed.
- N7 durability: `progress.sqlite` survives an app update (migration test)
  and a dictionary rebuild (lemma remap test).

## 3. Milestones

| # | Milestone | Proves | Status |
|---|---|---|---|
| M1 | Repo, `flutter create`, both DBs open, domain + tests green | plumbing, A10 | ✅ 33 tests |
| M2 | Review screen with swipe, flip, TTS, persistence, undo | A1–A8, A10 | ✅ on emulator |
| M3 | Word list + search + detail | B1–B4 | ✅ on emulator |
| M4 | Onboarding + calibration, stats, settings, export/import | C, D, E | ✅ built; export/import untested on device |
| M5 | Device pass on iPhone + Android, size check, TestFlight/APK | §2.6 | ⏳ |

### Measured so far (2026-09-12, Pixel 10 Pro XL emulator, arm64)

- Release APK: 28.0 MB arm64 / 25.6 MB armv7 per-ABI (≤ 60 MB ✓); the
  universal APK is 65.7 MB, which is why store builds use per-ABI splits or
  an app bundle.
- Startup, warm relaunch, release: Dart `main` → first frame 301 ms. The
  emulator adds ~5 s of engine start and ~2 s of GPU emulation before that,
  so A1's 1 s target must be judged on hardware.
- First launch copies the 17.8 MB dictionary out of the asset bundle:
  2.7 s on the emulator, behind the native splash.
- iOS build is blocked on this machine until the iOS 26.5 platform is
  installed in Xcode (Settings › Components); `Podfile` and project are set
  to iOS 15.

## 4. Open questions

1. iOS: tapping the IPA text vs a dedicated speaker button — both are in
   A3; keep both unless it clutters.
2. Whether the card back should scroll when three senses with examples
   overflow a small phone. *Proposal: yes, back face scrolls; front never.*
