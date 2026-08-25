import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/category_icons.dart';
import '../../../providers/shopping_provider.dart';
import 'quantity_selector.dart';

/// One row on the Cart screen: thumbnail, name, price at the chosen store,
/// quantity stepper, and a remove action. The store itself is shown once
/// per group via the section header, not repeated per row — swipe the row
/// (endToStart) to remove it as an alternative to the Remove label.
class CartItemTile extends ConsumerWidget {
  const CartItemTile({
    super.key,
    required this.entry,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onOpen,
  });

  final ShoppingListEntry entry;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context,WidgetRef ref) {
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  categoryIcon(entry.product.itemCategory),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.price == null
                          ? ref.tr('price_unavailable')
                          : ref.tr('price_each').replaceAll('{price}', entry.price!.price.toStringAsFixed(2)),
                      style: const TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  QuantitySelector(quantity: entry.quantity, onChanged: onQuantityChanged),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onRemove,
                    child: Text(
                      ref.tr('remove'),
                      style: TextStyle(fontSize: 11, color: AppColors.error),
                    ),
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
