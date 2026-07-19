import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productByIdProvider =
    FutureProvider.family<Product?, String>((ref, itemCode) {
  return ref.watch(productRepositoryProvider).getById(itemCode);
});

final productSearchProvider =
    FutureProvider.family<List<Product>, String>((ref, query) {
  return ref.watch(productRepositoryProvider).searchByName(query);
});

final productsByCategoryProvider =
    StreamProvider.family<List<Product>, String>((ref, itemCategory) {
  return ref.watch(productRepositoryProvider).watchByCategory(itemCategory);
});
