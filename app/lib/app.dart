import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings.dart';
import 'router.dart';

class WordwiseApp extends ConsumerWidget {
  const WordwiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const Settings();
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Wordwise',
      themeMode: settings.themeMode,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF3F6E9A), brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF3F6E9A), brightness: Brightness.dark, useMaterial3: true),
      routerConfig: router,
    );
  }
}
