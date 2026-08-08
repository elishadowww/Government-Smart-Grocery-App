import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/category_icons.dart';
import '../../../models/product.dart';

/// A saved product row (spec saved_product_screen.png): thumbnail, name,
/// category, cheapest price + store, unsave heart and an overflow menu.
class SavedProductTile extends StatelessWidget {
  const SavedProductTile({
    super.key,
    required this.product,
    this.price,
    this.storeName,
    required this.onOpen,
    required this.onUnsave,
    required this.onAddToList,
  });

  final Product product;
  final double? price;
  final String? storeName;
  final VoidCallback onOpen;
  final VoidCallback onUnsave;
  final VoidCallback onAddToList;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
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
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.itemCategory,
                      style: const TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          price == null ? 'Price unavailable' : 'RM${price!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (storeName != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              storeName!,
                              style: const TextStyle(fontSize: 11, color: AppColors.text),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  InkWell(
                    onTap: onUnsave,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.favorite, color: AppColors.error, size: 20),
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, color: AppColors.grey, size: 20),
                    onSelected: (value) {
                      if (value == 'remove') onUnsave();
                      if (value == 'add') onAddToList();
                      if (value == 'open') onOpen();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'open', child: Text('View Details')),
                      PopupMenuItem(value: 'add', child: Text('Add to List')),
                      PopupMenuItem(value: 'remove', child: Text('Remove')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
