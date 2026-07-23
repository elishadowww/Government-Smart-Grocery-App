import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price.dart';
import '../repositories/price_repository.dart';

final priceRepositoryProvider = Provider<PriceRepository>((ref) {
  return PriceRepository();
});

/// Current price for a product at every supermarket, cheapest first —
/// backs Module 1's price-comparison screen.
final latestPricesForItemProvider =
    FutureProvider.family<List<Price>, String>((ref, itemCode) {
  return ref.watch(priceRepositoryProvider).getLatestPricesForItem(itemCode);
});

/// Args bundle for [priceHistoryProvider], since `.family` only takes one
/// parameter.
class PriceHistoryQuery {
  const PriceHistoryQuery({required this.itemCode, this.premiseCode});

  final String itemCode;
  final String? premiseCode;

  @override
  bool operator ==(Object other) =>
      other is PriceHistoryQuery &&
      other.itemCode == itemCode &&
      other.premiseCode == premiseCode;

  @override
  int get hashCode => Object.hash(itemCode, premiseCode);
}

/// Historical prices for a product (optionally scoped to one supermarket) —
/// backs Module 4's price-trend chart.
final priceHistoryProvider =
    FutureProvider.family<List<Price>, PriceHistoryQuery>((ref, query) {
  return ref.watch(priceRepositoryProvider).getHistory(
        itemCode: query.itemCode,
        premiseCode: query.premiseCode,
      );
});
