import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies the bundled `words.sqlite` into the app-support directory. SQLite
/// cannot read an asset in place. The copy is refreshed when the bundled
/// `words.version` (the dictionary's `meta.built`) differs from the
/// installed one.
class AssetInstaller {
  AssetInstaller({this.assetDb = 'assets/words.sqlite', this.assetVersion = 'assets/words.version'});

  final String assetDb;
  final String assetVersion;

  Future<String> ensureInstalled() async {
    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, 'words.sqlite');
    final versionPath = p.join(dir.path, 'words.version');

    final bundled = (await rootBundle.loadString(assetVersion)).trim();
    final installed = File(versionPath).existsSync() ? File(versionPath).readAsStringSync().trim() : null;
    if (installed == bundled && File(dbPath).existsSync()) return dbPath;

    final bytes = await rootBundle.load(assetDb);
    final tmp = File('$dbPath.tmp');
    await tmp.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), flush: true);
    await tmp.rename(dbPath);
    await File(versionPath).writeAsString(bundled, flush: true);
    return dbPath;
  }
}
