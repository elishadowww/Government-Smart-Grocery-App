import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price.dart';
import '../models/product.dart';
import '../models/supermarket.dart';
import '../repositories/price_repository.dart';
import 'product_provider.dart';
import 'supermarket_provider.dart';

final priceRepositoryProvider = Provider<PriceRepository>((ref) {
  return PriceRepository();
});

/// A product stocked at a specific supermarket, paired with its current
/// price there — backs the Nearby Supermarket detail screen's catalogue.
typedef StoreCatalogEntry = ({Product product, double price});

/// Products currently stocked at [premiseCode], alphabetical by name — backs
/// the Nearby Supermarket detail screen's Product Catalogue section.
final storeCatalogProvider =
    FutureProvider.family<List<StoreCatalogEntry>, String>((ref, premiseCode) async {
  final prices = await ref.watch(priceRepositoryProvider).getLatestPricesForPremise(premiseCode);
  if (prices.isEmpty) return const [];

  final products = await ref
      .watch(productRepositoryProvider)
      .getByIds(prices.map((p) => p.itemCode).toList());

  final priceByItem = {for (final p in prices) p.itemCode: p.price};
  final entries = [
    for (final product in products) (product: product, price: priceByItem[product.itemCode]!),
  ];
  entries.sort((a, b) => a.product.name.compareTo(b.product.name));
  return entries;
});

/// A [StoreCatalogEntry] paired with the cheapest price found for that
/// product at any store — only entries where somewhere else is cheaper.
typedef StoreSaving = ({StoreCatalogEntry entry, double cheaperPrice});

/// Products at [premiseCode] that are cheaper elsewhere, biggest saving
/// first — backs the Nearby Supermarket detail screen's Price Comparison
/// section.
///
/// Keyed by [premiseCode] (a plain String, so Riverpod's family caching
/// actually works) rather than by the item-code list directly — a
/// `List<String>` built fresh in a widget's build() has a new identity every
/// rebuild, so watching a `.family` provider keyed by one directly never
/// settles: it looks like a brand new provider each time and restarts
/// loading forever instead of ever showing data.
final storeSavingsProvider =
    FutureProvider.family<List<StoreSaving>, String>((ref, premiseCode) async {
  final entries = await ref.watch(storeCatalogProvider(premiseCode).future);
  if (entries.isEmpty) return const [];

  final itemCodes = entries.map((e) => e.product.itemCode).toList();
  final cheapestByItem = await ref.watch(priceRepositoryProvider).getCheapestPrices(itemCodes);

  final savings = <StoreSaving>[];
  for (final entry in entries) {
    final cheapest = cheapestByItem[entry.product.itemCode]?.price;
    if (cheapest != null && cheapest < entry.price) {
      savings.add((entry: entry, cheaperPrice: cheapest));
    }
  }
  savings.sort((a, b) => (b.entry.price - b.cheaperPrice).compareTo(a.entry.price - a.cheaperPrice));
  return savings;
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
