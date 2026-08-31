import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price.dart';
import '../models/product.dart';
import '../repositories/price_repository.dart';
import '../repositories/shopping_repository.dart';
import 'current_user_provider.dart';
import 'price_provider.dart';
import 'product_provider.dart';
import 'supermarket_provider.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository();
});

/// Adds one unit of [itemCode] to the current user's cart, buying it from
/// [premiseCode] — backs the "Add to Cart" actions across the app, all of
/// which route through a store picker first (spec FR5) rather than
/// silently assuming the cheapest option. Returns false if there's no
/// session to attach the cart to (shouldn't normally happen — guests get a
/// temporary cart too, per spec §4).
Future<bool> addToShoppingListAt(WidgetRef ref, String itemCode, String premiseCode) async {
  final uid = ref.read(currentUidProvider);
  if (uid == null) return false;
  await ref.read(shoppingRepositoryProvider).addOrIncrementAt(uid, itemCode, premiseCode);
  ref.invalidate(shoppingListEntriesProvider);
  return true;
}

/// One row on the Cart screen: a product, how many the user wants, and the
/// price/store they chose for it (falls back to the cheapest store when no
/// choice is on record — e.g. a cart line added before store selection
/// existed).
class ShoppingListEntry {
  const ShoppingListEntry({
    required this.product,
    required this.quantity,
    this.price,
    this.storeName,
  });

  final Product product;
  final int quantity;
  final Price? price;
  final String? storeName;

  double? get subtotal => price == null ? null : price!.price * quantity;
}

/// The current user's cart, joined with product info and each item's
/// chosen store's price — backs the Cart screen.
final shoppingListEntriesProvider = FutureProvider<List<ShoppingListEntry>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const [];

  final rows = await ref.watch(shoppingRepositoryProvider).getAll(uid);
  if (rows.isEmpty) return const [];

  final itemCodes = rows.keys.toList();
  final products = await ref.watch(productRepositoryProvider).getByIds(itemCodes);
  final priceRepo = ref.watch(priceRepositoryProvider);

  // Resolve each item's chosen-store price; fall back to the cheapest
  // price when no store was chosen (legacy rows) or that store no longer
  // has a price on record for it.
  final chosenPrices = <String, Price>{};
  final needsFallback = <String>[];
  for (final product in products) {
    final premiseCode = rows[product.itemCode]!.premiseCode;
    final price = premiseCode == null ? null : await priceRepo.getLatestPrice(product.itemCode, premiseCode);
    if (price != null) {
      chosenPrices[product.itemCode] = price;
    } else {
      needsFallback.add(product.itemCode);
    }
  }

  final fallbackPrices =
      needsFallback.isEmpty ? const <String, Price>{} : await priceRepo.getCheapestPrices(needsFallback);

  final resolvedPrices = {...chosenPrices, ...fallbackPrices};
  final premiseCodes = {for (final price in resolvedPrices.values) price.premiseCode}.toList();
  final stores = await ref.watch(supermarketRepositoryProvider).getByIds(premiseCodes);
  final storeNameByCode = {for (final s in stores) s.premiseCode: s.name};

  return [
    for (final product in products)
      ShoppingListEntry(
        product: product,
        quantity: rows[product.itemCode]!.quantity,
        price: resolvedPrices[product.itemCode],
        storeName: resolvedPrices[product.itemCode] == null
            ? null
            : storeNameByCode[resolvedPrices[product.itemCode]!.premiseCode],
      ),
  ];
});

/// Total cost across the whole cart, summing only items with a known price
/// (spec §7.5 "Total Cost").
final shoppingListTotalProvider = Provider<double>((ref) {
  final entries = ref.watch(shoppingListEntriesProvider).value ?? const [];
  return entries.fold<double>(0, (sum, e) => sum + (e.subtotal ?? 0));
});

/// Total units across the cart (sum of quantities, not distinct products) —
/// backs the cart badge shown in the app bar on every screen.
final cartItemCountProvider = Provider<int>((ref) {
  final entries = ref.watch(shoppingListEntriesProvider).value ?? const [];
  return entries.fold<int>(0, (sum, e) => sum + e.quantity);
});

/// What buying every current cart item at [premiseCode] alone would cost.
/// [missingItemCount] is how many cart items that store has no price for
/// (excluded from [total]), so the UI can flag a partial/incomplete total
/// rather than silently understating it.
class StoreTotalOption {
  const StoreTotalOption({
    required this.premiseCode,
    required this.storeName,
    required this.total,
    required this.missingItemCount,
  });

  final String premiseCode;
  final String storeName;
  final double total;
  final int missingItemCount;
}

/// For each store already chosen somewhere in the cart (not the whole
/// nationwide dataset — just the handful of stores the user is already
/// touching), the total cost of buying every cart item from that one store.
/// Lets the Cart screen surface "you'd save RMx by buying everything from
/// store Y instead" without a nationwide scan.
final singleStoreTotalsProvider = FutureProvider<List<StoreTotalOption>>((ref) async {
  final entries = await ref.watch(shoppingListEntriesProvider.future);
  if (entries.isEmpty) return const [];

  final candidatePremiseCodes = {
    for (final e in entries)
      if (e.price != null) e.price!.premiseCode,
  }.toList();
  if (candidatePremiseCodes.length < 2) {
    // Nothing to compare against when the cart only touches one store.
    return const [];
  }

  final priceRepo = ref.watch(priceRepositoryProvider);
  final stores = await ref.watch(supermarketRepositoryProvider).getByIds(candidatePremiseCodes);
  final storeByCode = {for (final s in stores) s.premiseCode: s};

  final options = <StoreTotalOption>[];
  for (final premiseCode in candidatePremiseCodes) {
    final result = await _storeTotalFor(premiseCode, entries, priceRepo);
    options.add(StoreTotalOption(
      premiseCode: premiseCode,
      storeName: storeByCode[premiseCode]?.name ?? premiseCode,
      total: result.total,
      missingItemCount: result.missingItemCount,
    ));
  }

  options.sort((a, b) => a.total.compareTo(b.total));
  return options;
});

/// What buying every cart item from a single [premiseCode] would cost —
/// shared by [singleStoreTotalsProvider] (candidate stores already touched
/// by the cart) and [mixedStoreTotalProvider] (which needs the same
/// per-store total as its "beat this" baseline).
Future<({double total, int missingItemCount})> _storeTotalFor(
  String premiseCode,
  List<ShoppingListEntry> entries,
  PriceRepository priceRepo,
) async {
  var total = 0.0;
  var missing = 0;
  for (final entry in entries) {
    final price = await priceRepo.getLatestPrice(entry.product.itemCode, premiseCode);
    if (price == null) {
      missing++;
      continue;
    }
    total += price.price * entry.quantity;
  }
  return (total: total, missingItemCount: missing);
}

/// The cost of buying each cart item from whichever store currently has the
/// cheapest price for that specific item, plus how much it saves versus the
/// best single-store total — spec §7.5's "Mixed-Store Total": "recommends
/// the cheapest supermarket per item when it beats a single-store total."
class MixedStoreTotal {
  const MixedStoreTotal({
    required this.total,
    required this.missingItemCount,
    required this.storeCount,
    required this.savings,
  });

  final double total;
  final int missingItemCount;
  final int storeCount;
  final double savings;
}

/// Per-item cheapest-store optimization for the whole cart, scanning every
/// store nationwide for each item (via [PriceRepository.getCheapestPrices])
/// rather than just the stores already touched by the cart — unlike
/// [singleStoreTotalsProvider], the point here is finding savings *outside*
/// the stores already chosen.
///
/// Returns null when there's nothing to recommend: an empty cart, or a
/// mixed-store total that doesn't actually beat the best single-store total
/// (per the spec rule, it's only surfaced when it wins).
final mixedStoreTotalProvider = FutureProvider<MixedStoreTotal?>((ref) async {
  final entries = await ref.watch(shoppingListEntriesProvider.future);
  if (entries.isEmpty) return null;

  final priceRepo = ref.watch(priceRepositoryProvider);

  final itemCodes = [for (final e in entries) e.product.itemCode];
  final cheapestByItem = await priceRepo.getCheapestPrices(itemCodes);

  var mixedTotal = 0.0;
  var missing = 0;
  final storesUsed = <String>{};
  for (final entry in entries) {
    final price = cheapestByItem[entry.product.itemCode];
    if (price == null) {
      missing++;
      continue;
    }
    mixedTotal += price.price * entry.quantity;
    storesUsed.add(price.premiseCode);
  }

  // Baseline to beat: the cheapest total of buying everything from any one
  // store already touched by the cart.
  final candidatePremiseCodes = {
    for (final e in entries)
      if (e.price != null) e.price!.premiseCode,
  };
  double? bestSingleStoreTotal;
  for (final premiseCode in candidatePremiseCodes) {
    final result = await _storeTotalFor(premiseCode, entries, priceRepo);
    if (bestSingleStoreTotal == null || result.total < bestSingleStoreTotal) {
      bestSingleStoreTotal = result.total;
    }
  }
  if (bestSingleStoreTotal == null) return null;

  final savings = bestSingleStoreTotal - mixedTotal;
  if (savings <= 0) return null;

  return MixedStoreTotal(
    total: mixedTotal,
    missingItemCount: missing,
    storeCount: storesUsed.length,
    savings: savings,
  );
});

class ShoppingListController {
  ShoppingListController(this._ref);

  final Ref _ref;

  Future<void> setQuantity(String itemCode, int quantity) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    await _ref.read(shoppingRepositoryProvider).setQuantity(uid, itemCode, quantity);
    _ref.invalidate(shoppingListEntriesProvider);
  }

  Future<void> remove(String itemCode) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    await _ref.read(shoppingRepositoryProvider).remove(uid, itemCode);
    _ref.invalidate(shoppingListEntriesProvider);
  }

  /// Re-adds [itemCode] at [premiseCode] with [quantity] — backs the
  /// "Undo" action on the remove snackbar.
  Future<void> restore(String itemCode, String premiseCode, int quantity) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    await _ref
        .read(shoppingRepositoryProvider)
        .addOrIncrementAt(uid, itemCode, premiseCode, by: quantity);
    _ref.invalidate(shoppingListEntriesProvider);
  }

  Future<void> clearAll() async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    await _ref.read(shoppingRepositoryProvider).clearAll(uid);
    _ref.invalidate(shoppingListEntriesProvider);
  }
}

final shoppingListControllerProvider = Provider<ShoppingListController>((ref) {
  return ShoppingListController(ref);
});
