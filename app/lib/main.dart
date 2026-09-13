import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Copies the bundled dictionary on first launch; the native splash covers it.
  final dictionary = await openDictionary();
  runApp(
    ProviderScope(
      overrides: [dictionaryProvider.overrideWithValue(dictionary)],
      child: const WordwiseApp(),
    ),
  );
}
