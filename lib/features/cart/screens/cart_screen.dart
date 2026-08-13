import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../providers/shopping_provider.dart';
import '../widgets/cart_item_tile.dart';

/// Cart screen (spec §7.5, simplified: no mixed-store recommendation or
/// "Complete Shopping" archive flow — that's the rest of Module 3, out of
/// scope here). Reachable from the persistent cart icon in the app bar, the
/// Dashboard's "Cart" quick action, the nav drawer, and a "View" action on
/// the "Added to cart" snackbar.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(shoppingListEntriesProvider);
    final total = ref.watch(shoppingListTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if ((entriesAsync.value ?? const []).isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Clear Cart',
                  message: 'This will remove every item from your cart.',
                );
                if (confirmed == true) {
                  await ref.read(shoppingListControllerProvider).clearAll();
                }
              },
            ),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return AppEmptyState(
              icon: Icons.shopping_cart_outlined,
              message: 'Your cart is empty.\nAdd products while browsing or comparing prices.',
              actionLabel: 'Search Products',
              onAction: () => context.push('/search'),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return CartItemTile(
                      entry: entry,
                      onOpen: () => context.push('/product/${entry.product.itemCode}'),
                      onQuantityChanged: (qty) => ref
                          .read(shoppingListControllerProvider)
                          .setQuantity(entry.product.itemCode, qty),
                      onRemove: () async {
                        await ref
                            .read(shoppingListControllerProvider)
                            .remove(entry.product.itemCode);
                        if (context.mounted) {
                          showAppSnackBar(context, 'Removed from cart');
                        }
                      },
                    );
                  },
                ),
              ),
              _TotalBar(total: total),
            ],
          );
        },
        loading: () => const SkeletonListLoader(),
        error: (e, _) => InlineError(
          message: 'Could not load your cart.',
          onRetry: () => ref.invalidate(shoppingListEntriesProvider),
        ),
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Cost', style: TextStyle(fontSize: 15, color: AppColors.grey)),
          Text(
            'RM${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
