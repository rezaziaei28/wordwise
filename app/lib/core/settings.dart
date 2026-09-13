import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Keys in the `settings` table.
abstract final class SettingKeys {
  static const newPerDay = 'new_per_day';
  static const showIpa = 'show_ipa';
  static const ttsRate = 'tts_rate';
  static const theme = 'theme';
  static const onboarded = 'onboarded';
  static const nextNewRank = 'next_new_rank';
}

class Settings {
  const Settings({
    this.newPerDay = 50,
    this.showIpa = true,
    this.ttsRate = 0.45,
    this.themeMode = ThemeMode.system,
    this.onboarded = false,
  });

  final int newPerDay;
  final bool showIpa;
  final double ttsRate;
  final ThemeMode themeMode;
  final bool onboarded;

  Settings copyWith({int? newPerDay, bool? showIpa, double? ttsRate, ThemeMode? themeMode, bool? onboarded}) => Settings(
        newPerDay: newPerDay ?? this.newPerDay,
        showIpa: showIpa ?? this.showIpa,
        ttsRate: ttsRate ?? this.ttsRate,
        themeMode: themeMode ?? this.themeMode,
        onboarded: onboarded ?? this.onboarded,
      );

  static Settings fromMap(Map<String, String> m) => Settings(
        newPerDay: int.tryParse(m[SettingKeys.newPerDay] ?? '') ?? 50,
        showIpa: m[SettingKeys.showIpa] != '0',
        ttsRate: double.tryParse(m[SettingKeys.ttsRate] ?? '') ?? 0.45,
        themeMode: ThemeMode.values.asNameMap()[m[SettingKeys.theme]] ?? ThemeMode.system,
        onboarded: m[SettingKeys.onboarded] == '1',
      );
}

class SettingsNotifier extends AsyncNotifier<Settings> {
  @override
  Future<Settings> build() async {
    final s = Settings.fromMap(await ref.watch(progressRepositoryProvider).allSettings());
    await ref.read(ttsProvider).setRate(s.ttsRate);
    return s;
  }

  Future<void> _set(String key, String value, Settings next) async {
    await ref.read(progressRepositoryProvider).setSetting(key, value);
    state = AsyncData(next);
  }

  Future<void> setNewPerDay(int n) => _set(SettingKeys.newPerDay, '$n', state.requireValue.copyWith(newPerDay: n));
  Future<void> setShowIpa(bool v) => _set(SettingKeys.showIpa, v ? '1' : '0', state.requireValue.copyWith(showIpa: v));
  Future<void> setThemeMode(ThemeMode m) => _set(SettingKeys.theme, m.name, state.requireValue.copyWith(themeMode: m));
  Future<void> setOnboarded() => _set(SettingKeys.onboarded, '1', state.requireValue.copyWith(onboarded: true));
  Future<void> setTtsRate(double r) async {
    await ref.read(ttsProvider).setRate(r);
    await _set(SettingKeys.ttsRate, r.toStringAsFixed(2), state.requireValue.copyWith(ttsRate: r));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
