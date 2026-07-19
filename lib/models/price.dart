import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/constants/firestore_constants.dart';

/// A single price observation for a product at a supermarket on a given
/// date, sourced from PriceCatcher's `pricecatcher.csv`.
///
/// This model backs both Firestore collections that share the same shape:
/// - `prices`: full history, doc id `{itemCode}_{premiseCode}_{date}`
/// - `latest_prices`: one doc per (item, premise), the most recent price —
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

  factory Price.fromMap(Map<String, dynamic> map) {
    return Price(
      itemCode: map[PriceFields.itemCode] as String? ?? '',
      premiseCode: map[PriceFields.premiseCode] as String? ?? '',
      date: _parseDate(map[PriceFields.date]),
      price: (map[PriceFields.price] as num?)?.toDouble() ?? 0,
    );
  }

  factory Price.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Price.fromMap(doc.data() ?? const {});
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Deterministic doc id for the `prices` history collection.
  String get historyDocId => '${itemCode}_${premiseCode}_${_formatDate(date)}';

  /// Deterministic doc id for the `latest_prices` comparison collection.
  String get latestDocId => '${itemCode}_$premiseCode';

  Map<String, dynamic> toMap() {
    return {
      PriceFields.itemCode: itemCode,
      PriceFields.premiseCode: premiseCode,
      PriceFields.date: _formatDate(date),
      PriceFields.price: price,
    };
  }

  @override
  List<Object?> get props => [itemCode, premiseCode, date, price];
}
