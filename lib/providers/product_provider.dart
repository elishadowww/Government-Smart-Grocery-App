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
    FutureProvider.family<List<Product>, String>((ref, itemCategory) {
  return ref.watch(productRepositoryProvider).getByCategory(itemCategory);
});

/// Distinct product categories — backs the Filter bottom sheet's Category
/// dropdown (spec §7.3.2).
final productCategoriesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(productRepositoryProvider).getCategories();
});

/// Query bundle for [productSearchResultsProvider], since `.family` only
/// takes one parameter.
class ProductSearchQuery {
  const ProductSearchQuery({this.query = '', this.category});

  final String query;
  final String? category;

  @override
  bool operator ==(Object other) =>
      other is ProductSearchQuery &&
      other.query == query &&
      other.category == category;

  @override
  int get hashCode => Object.hash(query, category);
}

/// Search Products screen results: name substring search optionally
/// narrowed to a Filter category.
final productSearchResultsProvider =
    FutureProvider.family<List<Product>, ProductSearchQuery>((ref, args) {
  return ref.watch(productRepositoryProvider).search(
        query: args.query,
        category: args.category,
      );
});
