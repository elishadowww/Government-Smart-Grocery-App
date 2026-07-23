import '../core/constants/database_constants.dart';
import '../core/services/database_service.dart';
import '../models/supermarket.dart';

/// Data access for the local SQLite `supermarkets` table.
class SupermarketRepository {
  SupermarketRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  final DatabaseService _databaseService;

  Future<Supermarket?> getById(String premiseCode) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      DatabaseTables.supermarkets,
      where: '${SupermarketColumns.premiseCode} = ?',
      whereArgs: [premiseCode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Supermarket.fromMap(rows.first);
  }

  Future<List<Supermarket>> getByState(String state, {int limit = 100}) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      DatabaseTables.supermarkets,
      where: '${SupermarketColumns.state} = ?',
      whereArgs: [state],
      limit: limit,
    );
    return rows.map(Supermarket.fromMap).toList();
  }

  Future<List<Supermarket>> getByDistrict(String district, {int limit = 100}) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      DatabaseTables.supermarkets,
      where: '${SupermarketColumns.district} = ?',
      whereArgs: [district],
      limit: limit,
    );
    return rows.map(Supermarket.fromMap).toList();
  }

  /// Fetch multiple supermarkets by id in one query.
  Future<List<Supermarket>> getByIds(List<String> premiseCodes) async {
    if (premiseCodes.isEmpty) return const [];
    final db = await _databaseService.database;
    final placeholders = List.filled(premiseCodes.length, '?').join(',');
    final rows = await db.query(
      DatabaseTables.supermarkets,
      where: '${SupermarketColumns.premiseCode} IN ($placeholders)',
      whereArgs: premiseCodes,
    );
    return rows.map(Supermarket.fromMap).toList();
  }

  Future<List<Supermarket>> getAll({int limit = 100}) async {
    final db = await _databaseService.database;
    final rows = await db.query(DatabaseTables.supermarkets, limit: limit);
    return rows.map(Supermarket.fromMap).toList();
  }
}
