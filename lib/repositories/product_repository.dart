import '../core/constants/database_constants.dart';
import '../core/services/database_service.dart';
import '../models/product.dart';

/// Data access for the local SQLite `products` table.
class ProductRepository {
  ProductRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  final DatabaseService _databaseService;

  Future<Product?> getById(String itemCode) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      DatabaseTables.products,
      where: '${ProductColumns.itemCode} = ?',
      whereArgs: [itemCode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  /// Substring search over the product name (case-insensitive via the
  /// precomputed `name_lower` column).
  Future<List<Product>> searchByName(String query, {int limit = 20}) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return const [];

    final db = await _databaseService.database;
    final rows = await db.query(
      DatabaseTables.products,
      where: '${ProductColumns.nameLower} LIKE ?',
      whereArgs: ['%$term%'],
      orderBy: ProductColumns.nameLower,
      limit: limit,
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> getByCategory(String itemCategory, {int limit = 50}) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      DatabaseTables.products,
      where: '${ProductColumns.itemCategory} = ?',
      whereArgs: [itemCategory],
      orderBy: ProductColumns.nameLower,
      limit: limit,
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> getAll({int limit = 50}) async {
    final db = await _databaseService.database;
    final rows = await db.query(DatabaseTables.products, limit: limit);
    return rows.map(Product.fromMap).toList();
  }
}
