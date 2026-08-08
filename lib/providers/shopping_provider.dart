import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price.dart';
import '../models/product.dart';
import '../repositories/shopping_repository.dart';
import 'current_user_provider.dart';
import 'price_provider.dart';
import 'product_provider.dart';
import 'supermarket_provider.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository();
});

/// Adds one unit of [itemCode] to the current user's shopping list. Backs
/// the "Add to List" / "Add to Cart" actions on search results and the
/// product detail screen (spec FR5). Returns false if there's no session to
/// attach the list to (shouldn't normally happen — guests get a temporary
/// list too, per spec §4).
Future<bool> addToShoppingList(WidgetRef ref, String itemCode) async {
  final uid = ref.read(currentUidProvider);
  if (uid == null) return false;
  await ref.read(shoppingRepositoryProvider).addOrIncrement(uid, itemCode);
  ref.invalidate(shoppingListEntriesProvider);
  return true;
}

/// One row on the Shopping List screen: a product, how many the user wants,
/// and its current cheapest price/store (may be null if price data isn't
/// available for that item).
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

/// The current user's shopping list, joined with product info and cheapest
/// prices — backs the Shopping List / Cart screen.
final shoppingListEntriesProvider = FutureProvider<List<ShoppingListEntry>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const [];

  final quantities = await ref.watch(shoppingRepositoryProvider).getAll(uid);
  if (quantities.isEmpty) return const [];

  final itemCodes = quantities.keys.toList();
  final products = await ref.watch(productRepositoryProvider).getByIds(itemCodes);
  final priceMap = await ref.watch(priceRepositoryProvider).getCheapestPrices(itemCodes);

  final premiseCodes = {for (final price in priceMap.values) price.premiseCode}.toList();
  final stores = await ref.watch(supermarketRepositoryProvider).getByIds(premiseCodes);
  final storeNameByCode = {for (final s in stores) s.premiseCode: s.name};

  return [
    for (final product in products)
      ShoppingListEntry(
        product: product,
        quantity: quantities[product.itemCode] ?? 1,
        price: priceMap[product.itemCode],
        storeName: priceMap[product.itemCode] == null
            ? null
            : storeNameByCode[priceMap[product.itemCode]!.premiseCode],
      ),
  ];
});

/// Total cost across the whole shopping list, summing only items with a
/// known price (spec §7.5 "Total Cost").
final shoppingListTotalProvider = Provider<double>((ref) {
  final entries = ref.watch(shoppingListEntriesProvider).value ?? const [];
  return entries.fold<double>(0, (sum, e) => sum + (e.subtotal ?? 0));
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
