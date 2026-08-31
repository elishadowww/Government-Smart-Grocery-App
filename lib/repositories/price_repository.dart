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
  /// [premiseCode] and/or one calendar [month] (format `'YYYY-MM'`),
  /// newest first. Powers Module 4 (price trends).
  ///
  /// [limit] is only a safety cap for the unscoped "all months" case — pass
  /// null (the default) to fetch everything matching the filters, which is
  /// what callers scoping to a single month want.
  Future<List<Price>> getHistory({
    required String itemCode,
    String? premiseCode,
    String? month,
    int? limit,
  }) async {
    final db = await _databaseService.database;
    final where = StringBuffer('${PriceColumns.itemCode} = ?');
    final args = <Object?>[itemCode];

    if (premiseCode != null) {
      where.write(' AND ${PriceColumns.premiseCode} = ?');
      args.add(premiseCode);
    }
    if (month != null) {
      where.write(' AND ${PriceColumns.date} >= ? AND ${PriceColumns.date} < ?');
      args.add('$month-01');
      args.add(_nextMonthStart(month));
    }

    final rows = await db.query(
      DatabaseTables.prices,
      where: where.toString(),
      whereArgs: args,
      orderBy: '${PriceColumns.date} DESC',
      limit: limit,
    );
    return rows.map(Price.fromMap).toList();
  }

  /// Calendar months (format `'YYYY-MM'`, newest first) for which
  /// [itemCode] has any price history — backs the price-trend screen's
  /// month picker.
  Future<List<String>> getAvailableMonths(String itemCode) async {
    final db = await _databaseService.database;
    final rows = await db.rawQuery(
      '''
      SELECT DISTINCT substr(${PriceColumns.date}, 1, 7) AS ym
      FROM ${DatabaseTables.prices}
      WHERE ${PriceColumns.itemCode} = ?
      ORDER BY ym DESC
      ''',
      [itemCode],
    );
    return rows.map((row) => row['ym'] as String).toList();
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

  /// First day of the month after [month] (format `'YYYY-MM'`), as an ISO
  /// date string — the exclusive upper bound for a "within this month"
  /// range query.
  static String _nextMonthStart(String month) {
    final year = int.parse(month.substring(0, 4));
    final monthNum = int.parse(month.substring(5, 7));
    final next = monthNum == 12 ? DateTime(year + 1, 1) : DateTime(year, monthNum + 1);
    final y = next.year.toString().padLeft(4, '0');
    final m = next.month.toString().padLeft(2, '0');
    return '$y-$m-01';
  }
}
