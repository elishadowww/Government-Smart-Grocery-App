import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Thrown when the bundled database parts haven't been placed yet.
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
/// so this reassembles it from the bundled parts at
/// assets/database/pricecatcher.db.part000, .part001, ... into that
/// location once, then opens it. Every later launch finds the file already
/// there and opens it directly.
///
/// The database is split into parts at build time because the whole file
/// (over 1GB) cannot be loaded as a single Flutter asset — [rootBundle.load]
/// hits a hard Dart VM ceiling (`NewExternalTypedData` max length is
/// 1,073,741,823 bytes, just under 1GiB) and fails silently at the engine
/// level for anything larger, which is indistinguishable from a hang from
/// the app's point of view. Each part must stay under that limit; see
/// assets/database/ for how the current split was produced.
///
/// The copy is time-limited and written to a temp file first, then renamed
/// into place on success — a crash, timeout, or low-storage failure
/// partway through never leaves a corrupt file at the real path for a later
/// retry to mistake for "already copied".
///
/// No version checking — per project decision, keep this simple: if a local
/// copy exists, open it; otherwise copy it from assets.
class DatabaseService {
  DatabaseService();

  static const String _assetDir = 'assets/database';
  static const String _assetBaseName = 'pricecatcher.db';
  static const String _fileName = 'pricecatcher.db';

  /// Sanity cap on how many parts we'll look for — at 300MB/part this is
  /// ~19GB, far beyond anything this dataset should reach. Just a guard
  /// against looping forever if asset probing ever behaves unexpectedly.
  static const int _maxParts = 64;

  /// Only used to make the progress bar move smoothly before the final
  /// part; the copy loop itself doesn't depend on this being accurate.
  /// Current split (see assets/database/) is 16 parts at 90MB each, sized
  /// to stay under GitHub's 100MB per-file push limit.
  static const int _expectedPartsHint = 16;

  /// First-launch copy can take a while on slow storage; past this, surface
  /// a clear error instead of leaving the user staring at a spinner forever.
  static const Duration _copyTimeout = Duration(minutes: 8);

  static const int _chunkSize = 4 * 1024 * 1024; // 4 MB per write

  // Static so every DatabaseService instance shares one open connection and
  // any concurrent first-launch copies are deduplicated onto the same future.
  static Future<Database>? _openFuture;

  static final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  /// Copy progress in [0.0, 1.0] while the first-launch copy is running, so
  /// the loading screen can show real progress instead of a bare spinner.
  /// No events are emitted once the database is already in place.
  Stream<double> get copyProgress => _progressController.stream;

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
      await _copyFromAssets(targetPath).timeout(
        _copyTimeout,
        onTimeout: () => throw DatabaseNotAvailableException(
          'Copying the local database timed out after ${_copyTimeout.inMinutes} minutes.\n\n'
          'This usually means the device is low on free storage (the database '
          'needs a few GB free) or storage is unusually slow. Free up space '
          'and try again.',
        ),
      );
    }

    return openDatabase(targetPath);
  }

  Future<void> _copyFromAssets(String targetPath) async {
    _progressController.add(0);

    await Directory(p.dirname(targetPath)).create(recursive: true);

    // Write to a temp file and rename into place on success. Without this,
    // a copy that fails or times out partway through leaves a truncated
    // file at [targetPath] — [_open] would then see "file exists", skip
    // copying on the next attempt, and hand sqflite a corrupt database.
    final tempFile = File('$targetPath.part');

    try {
      var partsCopied = 0;

      final raf = await tempFile.open(mode: FileMode.write);
      try {
        for (var i = 0; i < _maxParts; i++) {
          final assetPath =
              '$_assetDir/$_assetBaseName.part${i.toString().padLeft(3, '0')}';

          final ByteData data;
          try {
            data = await rootBundle.load(assetPath);
          } catch (_) {
            break; // No more parts — normal end of the sequence.
          }

          final total = data.lengthInBytes;
          var written = 0;
          while (written < total) {
            final end = (written + _chunkSize).clamp(0, total);
            await raf.writeFrom(
              data.buffer.asUint8List(data.offsetInBytes + written, end - written),
            );
            written = end;
          }

          partsCopied++;
          _progressController.add((partsCopied / _expectedPartsHint).clamp(0.0, 0.98));
        }

        await raf.flush();
      } finally {
        await raf.close();
      }

      if (partsCopied == 0) {
        throw const DatabaseNotAvailableException(
          'The bundled database was not found in assets/database/.\n\n'
          'Ask the project maintainer for the latest database parts '
          '(pricecatcher.db.part000, .part001, ...) and place them in '
          'assets/database/, then restart the app.',
        );
      }

      await tempFile.rename(targetPath);
      _progressController.add(1);
    } catch (error) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }
}
