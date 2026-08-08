import 'package:sqflite/sqflite.dart';

import '../core/constants/user_data_constants.dart';
import '../core/services/user_data_service.dart';

/// Tracks which products a user has recently opened, scoped per Firebase
/// uid — backs the Dashboard's "Recent Products" list (spec §7.1).
class RecentProductRepository {
  RecentProductRepository({UserDataService? service})
      : _service = service ?? UserDataService();

  final UserDataService _service;

  Future<void> recordView(String uid, String itemCode) async {
    final db = await _service.database;
    await db.insert(
      UserDataTables.recentProducts,
      {
        RecentProductColumns.uid: uid,
        RecentProductColumns.itemCode: itemCode,
        RecentProductColumns.viewedAt: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getRecent(String uid, {int limit = 5}) async {
    final db = await _service.database;
    final rows = await db.query(
      UserDataTables.recentProducts,
      where: '${RecentProductColumns.uid} = ?',
      whereArgs: [uid],
      orderBy: '${RecentProductColumns.viewedAt} DESC',
      limit: limit,
    );
    return rows.map((r) => r[RecentProductColumns.itemCode] as String).toList();
  }
}
