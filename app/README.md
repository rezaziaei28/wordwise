# app/ — the Wordwise Flutter app

Design: [`../design/`](../design/) (03 = architecture, 04 = MVP acceptance
criteria). Bundle id `space.jadi.wordwise`.

```sh
make -C ../data install-app        # put the built dictionary into assets/
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift codegen
flutter test
flutter run                        # or: flutter build apk --release --split-per-abi
```

Layout (`lib/`): `domain/` pure Dart (models, scheduler, queue policy) ·
`data/` dictionary (sqlite3, read-only) and progress (drift) · `features/`
review, words, onboarding, stats, settings · `core/` providers, settings,
grade styling · `router.dart`, `app.dart`, `main.dart`.

Tests: `test/domain` (scheduler, queue), `test/data` (repository against an
in-memory DB), `test/features` (review controller end to end with an
in-memory dictionary), `test/widgets` (swipe gestures).
