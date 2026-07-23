import 'package:equatable/equatable.dart';

import '../core/constants/database_constants.dart';

/// A single price observation for a product at a supermarket on a given
/// date, sourced from PriceCatcher's `pricecatcher.csv` files.
///
/// This model backs both SQLite tables that share the same shape:
/// - `prices`: full history, one row per (item, premise, date)
/// - `latest_prices`: one row per (item, premise), the most recent price —
///   what price-comparison screens should query.
class Price extends Equatable {
  const Price({
    required this.itemCode,
    required this.premiseCode,
    required this.date,
    required this.price,
  });

  final String itemCode;
  final String premiseCode;
  final DateTime date;
  final double price;

  factory Price.fromMap(Map<String, Object?> row) {
    return Price(
      itemCode: row[PriceColumns.itemCode] as String? ?? '',
      premiseCode: row[PriceColumns.premiseCode] as String? ?? '',
      date: _parseDate(row[PriceColumns.date] as String?),
      price: (row[PriceColumns.price] as num?)?.toDouble() ?? 0,
    );
  }

  static DateTime _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.parse(value);
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, Object?> toMap() {
    return {
      PriceColumns.itemCode: itemCode,
      PriceColumns.premiseCode: premiseCode,
      PriceColumns.date: _formatDate(date),
      PriceColumns.price: price,
    };
  }

  @override
  List<Object?> get props => [itemCode, premiseCode, date, price];
}
