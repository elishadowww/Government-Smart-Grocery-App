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

  /// Name substring search optionally narrowed to one category — backs the
  /// Search Products screen once a Filter category is applied (spec §7.3).
  /// An empty [query] with a [category] browses that category; an empty
  /// query with no category returns nothing (search requires input).
  ///
  /// [terms], if given, ORs together a substring match per term instead of
  /// matching [query] alone — used to also match Malay alias terms for an
  /// English query (see search_aliases.dart), since the dataset's product
  /// names are Malay-only. Falls back to plain [query] matching when empty.
  Future<List<Product>> search({
    String query = '',
    List<String> terms = const [],
    String? category,
    int limit = 30,
  }) async {
    final normalizedTerms = terms.map((t) => t.trim().toLowerCase()).where((t) => t.isNotEmpty).toSet();
    final term = query.trim().toLowerCase();
    if (normalizedTerms.isEmpty && term.isEmpty && (category == null || category.isEmpty)) {
      return const [];
    }

    final db = await _databaseService.database;
    final where = <String>[];
    final args = <Object?>[];

    if (normalizedTerms.isNotEmpty) {
      final nameClauses = normalizedTerms.map((_) => '${ProductColumns.nameLower} LIKE ?').join(' OR ');
      where.add('($nameClauses)');
      args.addAll(normalizedTerms.map((t) => '%$t%'));
    } else if (term.isNotEmpty) {
      where.add('${ProductColumns.nameLower} LIKE ?');
      args.add('%$term%');
    }

    if (category != null && category.isNotEmpty) {
      where.add('${ProductColumns.itemCategory} = ?');
      args.add(category);
    }

    final rows = await db.query(
      DatabaseTables.products,
      where: where.join(' AND '),
      whereArgs: args,
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

  /// Fetch multiple products by id in one query, in no particular order —
  /// callers that need a specific order (e.g. most-recently-saved first)
  /// should re-sort by the id list themselves.
  Future<List<Product>> getByIds(List<String> itemCodes) async {
    if (itemCodes.isEmpty) return const [];
    final db = await _databaseService.database;
    final placeholders = List.filled(itemCodes.length, '?').join(',');
    final rows = await db.query(
      DatabaseTables.products,
      where: '${ProductColumns.itemCode} IN ($placeholders)',
      whereArgs: itemCodes,
    );
    final byId = {for (final row in rows.map(Product.fromMap)) row.itemCode: row};
    return [for (final id in itemCodes) if (byId[id] != null) byId[id]!];
  }

  /// Distinct product categories, alphabetical — backs the Filter bottom
  /// sheet's Category dropdown (spec §7.3.2).
  Future<List<String>> getCategories() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      DatabaseTables.products,
      columns: [ProductColumns.itemCategory],
      distinct: true,
      where: "${ProductColumns.itemCategory} != ''",
      orderBy: ProductColumns.itemCategory,
    );
    return rows.map((r) => r[ProductColumns.itemCategory] as String).toList();
  }
}
