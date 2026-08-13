import 'package:sqflite/sqflite.dart';

import '../core/constants/user_data_constants.dart';
import '../core/services/user_data_service.dart';

/// Data access for saved products (spec FR8), scoped per Firebase uid so
/// guest and registered sessions on the same device never mix data.
///
/// Saving a product also records the price it was saved at
/// ([SavedProductColumns.trackedPrice]) — that's the baseline
/// [NotificationRepository] compares against to raise a price-change alert
/// (spec §7.9: "saving a product automatically enables price tracking").
class SavedProductRepository {
  SavedProductRepository({UserDataService? service})
      : _service = service ?? UserDataService();

  final UserDataService _service;

  Future<bool> isSaved(String uid, String itemCode) async {
    final db = await _service.database;
    final rows = await db.query(
      UserDataTables.savedProducts,
      where: '${SavedProductColumns.uid} = ? AND ${SavedProductColumns.itemCode} = ?',
      whereArgs: [uid, itemCode],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> save(String uid, String itemCode, {double? price}) async {
    final db = await _service.database;
    await db.insert(
      UserDataTables.savedProducts,
      {
        SavedProductColumns.uid: uid,
        SavedProductColumns.itemCode: itemCode,
        SavedProductColumns.savedAt: DateTime.now().toIso8601String(),
        SavedProductColumns.trackedPrice: price,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> unsave(String uid, String itemCode) async {
    final db = await _service.database;
    await db.delete(
      UserDataTables.savedProducts,
      where: '${SavedProductColumns.uid} = ? AND ${SavedProductColumns.itemCode} = ?',
      whereArgs: [uid, itemCode],
    );
  }

  /// Saved item codes, most recently saved first.
  Future<List<String>> getSavedItemCodes(String uid) async {
    final db = await _service.database;
    final rows = await db.query(
      UserDataTables.savedProducts,
      where: '${SavedProductColumns.uid} = ?',
      whereArgs: [uid],
      orderBy: '${SavedProductColumns.savedAt} DESC',
    );
    return rows.map((r) => r[SavedProductColumns.itemCode] as String).toList();
  }

  /// itemCode -> price it was saved/last-notified at, for the whole saved
  /// set. Used by [NotificationRepository] to detect price changes.
  Future<Map<String, double?>> getTrackedPrices(String uid) async {
    final db = await _service.database;
    final rows = await db.query(
      UserDataTables.savedProducts,
      where: '${SavedProductColumns.uid} = ?',
      whereArgs: [uid],
    );
    return {
      for (final r in rows)
        r[SavedProductColumns.itemCode] as String:
            (r[SavedProductColumns.trackedPrice] as num?)?.toDouble(),
    };
  }

  Future<void> updateTrackedPrice(
    String uid,
    String itemCode,
    double price,
  ) async {
    final db = await _service.database;
    await db.update(
      UserDataTables.savedProducts,
      {SavedProductColumns.trackedPrice: price},
      where: '${SavedProductColumns.uid} = ? AND ${SavedProductColumns.itemCode} = ?',
      whereArgs: [uid, itemCode],
    );
  }
}
