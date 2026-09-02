import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../models/product.dart';
import '../localization/app_strings.dart';
import '../utils/category_icons.dart';
import 'app_button.dart';

/// Search-result product card (spec §7.3 "Product Card — Component Spec":
/// name, category, unit, cheapest price + store, Compare Prices / Add).
class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.cheapestPrice,
    this.cheapestStoreName,
    this.isSaved = false,
    this.onTap,
    this.onToggleSave,
    this.onComparePrices,
    this.onAdd,
  });

  final Product product;

  /// Null while the batch price lookup for this result page hasn't
  /// resolved yet, or if the product has no recorded price.
  final double? cheapestPrice;
  final String? cheapestStoreName;

  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onToggleSave;
  final VoidCallback? onComparePrices;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(categoryIcon(product.itemCategory), color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        Tooltip(
                          message: isSaved
                              ? ref.tr('remove_from_favourites')
                              : ref.tr('add_to_favourites'),
                          child: InkWell(
                            onTap: onToggleSave,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                isSaved ? Icons.favorite : Icons.favorite_border,
                                size: 20,
                                color: isSaved ? AppColors.error : AppColors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${ref.tr('category')}: ${product.itemCategory}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.grey),
                          ),
                        ),
                        Text(
                          '${ref.tr('unit')}: ${product.unit}',
                          style: const TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _CheapestPriceLine(price: cheapestPrice, storeName: cheapestStoreName),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: ref.tr('compare'),
                            type: AppButtonType.outlined,
                            dense: true,
                            icon: Icons.compare_arrows,
                            onPressed: onComparePrices,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                            label: ref.tr('add'),
                            type: AppButtonType.filled,
                            dense: true,
                            icon: Icons.add_shopping_cart,
                            onPressed: onAdd,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheapestPriceLine extends ConsumerWidget {
  const _CheapestPriceLine({required this.price, required this.storeName});

  final double? price;
  final String? storeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (price == null) {
      return Text(
        ref.tr('price_unavailable'),
        style: const TextStyle(fontSize: 13, color: AppColors.grey),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppColors.grey),
        children: [
          TextSpan(text: '${ref.tr('cheapest')}: '),
          TextSpan(
            text: 'RM${price!.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
          if (storeName != null) TextSpan(text: ' ($storeName)'),
        ],
      ),
    );
  }
}
