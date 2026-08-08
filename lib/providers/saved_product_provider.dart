import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../repositories/saved_product_repository.dart';
import 'current_user_provider.dart';
import 'price_provider.dart';
import 'product_provider.dart';

final savedProductRepositoryProvider = Provider<SavedProductRepository>((ref) {
  return SavedProductRepository();
});

/// Saved item codes for the current session, most recently saved first.
/// Call `ref.invalidate(savedItemCodesProvider)` after save/unsave.
final savedItemCodesProvider = FutureProvider<List<String>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const [];
  return ref.watch(savedProductRepositoryProvider).getSavedItemCodes(uid);
});

final isProductSavedProvider = FutureProvider.family<bool, String>((ref, itemCode) async {
  final saved = await ref.watch(savedItemCodesProvider.future);
  return saved.contains(itemCode);
});

/// Full [Product] rows for everything the current user has saved — backs
/// the Saved Products screen.
final savedProductsProvider = FutureProvider<List<Product>>((ref) async {
  final itemCodes = await ref.watch(savedItemCodesProvider.future);
  if (itemCodes.isEmpty) return const [];
  return ref.watch(productRepositoryProvider).getByIds(itemCodes);
});

/// Toggle-save / unsave, keeping the price-tracking baseline used by
/// price-change notifications (spec §7.9) in sync.
class SavedProductsController {
  SavedProductsController(this._ref);

  final Ref _ref;

  Future<void> save(String itemCode) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;

    double? cheapest;
    try {
      final prices = await _ref.read(latestPricesForItemProvider(itemCode).future);
      if (prices.isNotEmpty) cheapest = prices.first.price;
    } catch (_) {
      // Price lookup failing shouldn't block saving the product itself.
    }

    await _ref
        .read(savedProductRepositoryProvider)
        .save(uid, itemCode, price: cheapest);
    _ref.invalidate(savedItemCodesProvider);
  }

  Future<void> unsave(String itemCode) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    await _ref.read(savedProductRepositoryProvider).unsave(uid, itemCode);
    _ref.invalidate(savedItemCodesProvider);
  }
}

final savedProductsControllerProvider = Provider<SavedProductsController>((ref) {
  return SavedProductsController(ref);
});
