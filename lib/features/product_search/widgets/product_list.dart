import 'package:flutter/material.dart';

import '../../../core/widgets/product_card.dart';
import '../../../models/price.dart';
import '../../../models/product.dart';

/// A search result row: a product plus its resolved cheapest price/store
/// (both may still be null if price data isn't available for that item).
class ProductSearchResult {
  const ProductSearchResult({required this.product, this.price, this.storeName});

  final Product product;
  final Price? price;
  final String? storeName;
}

/// Renders search results as product cards (spec §7.3, ListView.builder per
/// dev notes). Loading/empty/error states are handled by the caller
/// ([SkeletonListLoader] / [AppEmptyState] / [InlineError]) since they
/// depend on why there's nothing to show.
class ProductResultList extends StatelessWidget {
  const ProductResultList({
    super.key,
    required this.results,
    required this.savedItemCodes,
    required this.onOpenProduct,
    required this.onComparePrices,
    required this.onToggleSave,
    required this.onAdd,
  });

  final List<ProductSearchResult> results;
  final Set<String> savedItemCodes;
  final ValueChanged<Product> onOpenProduct;
  final ValueChanged<Product> onComparePrices;
  final ValueChanged<Product> onToggleSave;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final result = results[index];
        return ProductCard(
          product: result.product,
          cheapestPrice: result.price?.price,
          cheapestStoreName: result.storeName,
          isSaved: savedItemCodes.contains(result.product.itemCode),
          onTap: () => onOpenProduct(result.product),
          onComparePrices: () => onComparePrices(result.product),
          onToggleSave: () => onToggleSave(result.product),
          onAdd: () => onAdd(result.product),
        );
      },
    );
  }
}
