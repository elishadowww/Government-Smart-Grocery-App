import 'package:sqflite/sqflite.dart';

import '../core/constants/user_data_constants.dart';
import '../core/services/user_data_service.dart';

/// Data access for a user's recent product searches (spec §7.3 "Recent
/// Searches" chips), scoped per Firebase uid.
class RecentSearchRepository {
  RecentSearchRepository({UserDataService? service})
      : _service = service ?? UserDataService();

  final UserDataService _service;

  /// Re-searching an existing term just bumps it to the top rather than
  /// creating a duplicate chip.
  Future<void> add(String uid, String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;

    final db = await _service.database;
    await db.insert(
      UserDataTables.recentSearches,
      {
        RecentSearchColumns.uid: uid,
        RecentSearchColumns.term: trimmed,
        RecentSearchColumns.searchedAt: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getRecent(String uid, {int limit = 8}) async {
    final db = await _service.database;
    final rows = await db.query(
      UserDataTables.recentSearches,
      where: '${RecentSearchColumns.uid} = ?',
      whereArgs: [uid],
      orderBy: '${RecentSearchColumns.searchedAt} DESC',
      limit: limit,
    );
    return rows.map((r) => r[RecentSearchColumns.term] as String).toList();
  }

  Future<void> clearAll(String uid) async {
    final db = await _service.database;
    await db.delete(
      UserDataTables.recentSearches,
      where: '${RecentSearchColumns.uid} = ?',
      whereArgs: [uid],
    );
  }
}
