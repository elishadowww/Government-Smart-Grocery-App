import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../repositories/recent_product_repository.dart';
import 'current_user_provider.dart';
import 'product_provider.dart';

final recentProductRepositoryProvider = Provider<RecentProductRepository>((ref) {
  return RecentProductRepository();
});

/// Recently viewed products for the Dashboard's "Recent Products" list
/// (spec §7.1), most recent first.
final recentProductsProvider = FutureProvider<List<Product>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const [];

  final itemCodes = await ref.watch(recentProductRepositoryProvider).getRecent(uid);
  if (itemCodes.isEmpty) return const [];

  return ref.watch(productRepositoryProvider).getByIds(itemCodes);
});

Future<void> recordProductView(WidgetRef ref, String itemCode) async {
  final uid = ref.read(currentUidProvider);
  if (uid == null) return;
  await ref.read(recentProductRepositoryProvider).recordView(uid, itemCode);
  ref.invalidate(recentProductsProvider);
}
