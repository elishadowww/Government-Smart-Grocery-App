import '../core/constants/database_constants.dart';
import '../core/services/database_service.dart';
import '../models/price.dart';

/// Data access for price data: the `latest_prices` comparison table and the
/// `prices` full history table.
class PriceRepository {
  PriceRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  final DatabaseService _databaseService;

  /// Current price for [itemCode] at every supermarket that stocks it,
  /// cheapest first. This is what Module 1's price-comparison screen
  /// should call.
  Future<List<Price>> getLatestPricesForItem(
    String itemCode, {
    int limit = 100,
  }) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      DatabaseTables.latestPrices,
      where: '${PriceColumns.itemCode} = ?',
      whereArgs: [itemCode],
      orderBy: PriceColumns.price,
      limit: limit,
    );
    return rows.map(Price.fromMap).toList();
  }

  /// Current price for every product stocked at [premiseCode] — backs the
  /// Nearby Supermarket detail screen's product catalogue.
  Future<List<Price>> getLatestPricesForPremise(
    String premiseCode, {
    int limit = 200,
  }) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      DatabaseTables.latestPrices,
      where: '${PriceColumns.premiseCode} = ?',
      whereArgs: [premiseCode],
      limit: limit,
    );
    return rows.map(Price.fromMap).toList();
  }

  /// Current price for [itemCode] at a single [premiseCode], if any.
  Future<Price?> getLatestPrice(String itemCode, String premiseCode) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      DatabaseTables.latestPrices,
      where: '${PriceColumns.itemCode} = ? AND ${PriceColumns.premiseCode} = ?',
      whereArgs: [itemCode, premiseCode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Price.fromMap(rows.first);
  }

  /// Historical prices for [itemCode], optionally scoped to one
  /// [premiseCode], ordered oldest to newest. Powers Module 4 (price
  /// trends).
  Future<List<Price>> getHistory({
    required String itemCode,
    String? premiseCode,
    DateTime? since,
    int limit = 200,
  }) async {
    final db = await _databaseService.database;
    final where = StringBuffer('${PriceColumns.itemCode} = ?');
    final args = <Object?>[itemCode];

    if (premiseCode != null) {
      where.write(' AND ${PriceColumns.premiseCode} = ?');
      args.add(premiseCode);
    }
    if (since != null) {
      where.write(' AND ${PriceColumns.date} >= ?');
      args.add(_isoDate(since));
    }

    final rows = await db.query(
      DatabaseTables.prices,
      where: where.toString(),
      whereArgs: args,
      orderBy: PriceColumns.date,
      limit: limit,
    );
    return rows.map(Price.fromMap).toList();
  }

  /// Cheapest current price for each of [itemCodes], one row per item —
  /// backs product search result cards, which show only the cheapest price
  /// and store per product (spec §7.3 Product Card).
  Future<Map<String, Price>> getCheapestPrices(List<String> itemCodes) async {
    if (itemCodes.isEmpty) return const {};
    final db = await _databaseService.database;
    final placeholders = List.filled(itemCodes.length, '?').join(',');

    final rows = await db.rawQuery(
      '''
      SELECT lp.* FROM ${DatabaseTables.latestPrices} lp
      INNER JOIN (
        SELECT ${PriceColumns.itemCode}, MIN(${PriceColumns.price}) AS min_price
        FROM ${DatabaseTables.latestPrices}
        WHERE ${PriceColumns.itemCode} IN ($placeholders)
        GROUP BY ${PriceColumns.itemCode}
      ) cheapest
        ON lp.${PriceColumns.itemCode} = cheapest.${PriceColumns.itemCode}
       AND lp.${PriceColumns.price} = cheapest.min_price
      ''',
      itemCodes,
    );

    final result = <String, Price>{};
    for (final row in rows) {
      final price = Price.fromMap(row);
      // A tie at the same cheapest price across stores can return more than
      // one row per item; keep the first and ignore the rest.
      result.putIfAbsent(price.itemCode, () => price);
    }
    return result;
  }

  static String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
