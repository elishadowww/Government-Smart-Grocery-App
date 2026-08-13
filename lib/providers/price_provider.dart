import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price.dart';
import '../models/supermarket.dart';
import '../repositories/price_repository.dart';
import 'supermarket_provider.dart';

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

/// Cheapest current price per item, for a batch of items — backs the
/// Search Products result cards (spec §7.3 Product Card: "Cheapest: RMx.xx
/// (Store)").
final cheapestPricesProvider =
    FutureProvider.family<Map<String, Price>, List<String>>((ref, itemCodes) {
  return ref.watch(priceRepositoryProvider).getCheapestPrices(itemCodes);
});

/// Every supermarket carrying [itemCode] that has a current price — one row
/// per [latestPricesForItemProvider] entry. Backs the price comparison
/// screen and the product detail screen's mini comparison list, so both can
/// share Riverpod's caching instead of re-querying on every rebuild.
final priceComparisonStoresProvider =
    FutureProvider.family<List<Supermarket>, String>((ref, itemCode) async {
  final prices = await ref.watch(latestPricesForItemProvider(itemCode).future);
  final premiseCodes = prices.map((p) => p.premiseCode).toList();
  return ref.watch(supermarketRepositoryProvider).getByIds(premiseCodes);
});
