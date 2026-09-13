import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/dictionary/asset_installer.dart';
import '../data/dictionary/dictionary_repository.dart';
import '../data/progress/progress_db.dart';
import '../data/progress/progress_repository.dart';
import '../domain/scheduler.dart';

/// Opened once at startup (see `bootstrap` in app.dart) and overridden into
/// the ProviderScope, so every consumer reads synchronously.
final dictionaryProvider = Provider<DictionaryRepository>((ref) => throw UnimplementedError('overridden at bootstrap'));

/// The progress database runs on the main isolate: every query is a few
/// rows, and a background isolate cost ~10 s of startup in debug builds.
final progressDbProvider = Provider<ProgressDb>((ref) {
  final db = ProgressDb(LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    return NativeDatabase(File(p.join(dir.path, 'progress.sqlite')));
  }));
  ref.onDispose(db.close);
  return db;
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) => ProgressRepository(ref.watch(progressDbProvider)));

final schedulerConfigProvider = Provider<SchedulerConfig>((ref) => const SchedulerConfig());

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final ttsProvider = Provider<Tts>((ref) {
  final tts = Tts();
  ref.onDispose(tts.dispose);
  return tts;
});

/// Thin wrapper so the UI never touches flutter_tts directly (D-002).
/// `Tts.noop()` is used in tests and wherever no engine is available.
class Tts {
  Tts() : _tts = FlutterTts();
  Tts.noop() : _tts = null;

  final FlutterTts? _tts;
  bool _ready = false;
  double _rate = 0.45;

  Future<void> _init() async {
    if (_ready || _tts == null) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_rate);
    await _tts.awaitSpeakCompletion(false);
    _ready = true;
  }

  Future<void> speak(String text) async {
    await _init();
    if (_tts == null) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> setRate(double rate) async {
    _rate = rate;
    if (_ready) await _tts?.setSpeechRate(rate);
  }

  void dispose() {
    _tts?.stop();
  }
}

/// Bootstraps the dictionary: install the asset copy, open it read-only.
Future<DictionaryRepository> openDictionary() async {
  final path = await AssetInstaller().ensureInstalled();
  return DictionaryRepository.open(path);
}
