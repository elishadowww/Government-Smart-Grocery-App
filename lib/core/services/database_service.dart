import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Thrown when assets/database/pricecatcher.db hasn't been placed yet.
///
/// This is a development-time setup problem, not a runtime bug — a real
/// shipped build always has the asset baked in. The message is written for
/// whoever hits it locally, not an end user.
class DatabaseNotAvailableException implements Exception {
  const DatabaseNotAvailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Opens the local SQLite database backing the PriceCatcher catalog
/// (products, supermarkets, prices, latest_prices).
///
/// On first launch there is nothing at sqflite's managed database path yet,
/// so this copies the prepopulated database bundled at
/// assets/database/pricecatcher.db into that location once, then opens it.
/// Every later launch finds the file already there and opens it directly.
///
/// No version checking — per project decision, keep this simple: if a local
/// copy exists, open it; otherwise copy it from assets.
class DatabaseService {
  DatabaseService();

  static const String _assetPath = 'assets/database/pricecatcher.db';
  static const String _fileName = 'pricecatcher.db';

  // Static so every DatabaseService instance shares one open connection and
  // any concurrent first-launch copies are deduplicated onto the same future.
  static Future<Database>? _openFuture;

  Future<Database> get database {
    return _openFuture ??= _open().catchError((Object error, StackTrace stackTrace) {
      // Don't cache a failed attempt — otherwise a retry (e.g. after the
      // user places the missing asset and taps "Retry") would just replay
      // the same cached failure forever instead of trying again.
      _openFuture = null;
      return Future<Database>.error(error, stackTrace);
    });
  }

  Future<Database> _open() async {
    final targetPath = p.join(await getDatabasesPath(), _fileName);

    if (!await File(targetPath).exists()) {
      await _copyFromAssets(targetPath);
    }

    return openDatabase(targetPath);
  }

  Future<void> _copyFromAssets(String targetPath) async {
    final ByteData data;
    try {
      data = await rootBundle.load(_assetPath);
    } catch (_) {
      throw const DatabaseNotAvailableException(
        'pricecatcher.db was not found in assets/database/.\n\n'
        'Ask the project maintainer for the latest pricecatcher.db and place '
        'it at assets/database/pricecatcher.db, then restart the app.',
      );
    }

    await Directory(p.dirname(targetPath)).create(recursive: true);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(targetPath).writeAsBytes(bytes, flush: true);
  }
}
