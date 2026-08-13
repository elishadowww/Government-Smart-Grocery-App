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

/// Cart screen (spec §7.5, simplified: no "Complete Shopping" archive flow
/// — that's the rest of Module 3, out of scope here). Reachable from the
/// persistent cart icon in the app bar, the Dashboard's "Cart" quick
/// action, the nav drawer, and a "View" action on the "Added to cart"
/// snackbar.
///
/// Items are grouped by the store the user chose for each one (spec-driven
/// addition: Add to Cart now asks which store, rather than assuming
/// cheapest). A "Cheapest Single Store" card compares the total of buying
/// everything from just one store, scoped to the handful of stores already
/// touched by the cart — not a nationwide scan.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _removeWithUndo(BuildContext context, WidgetRef ref, ShoppingListEntry entry) async {
    final premiseCode = entry.price?.premiseCode;
    final quantity = entry.quantity;
    final itemCode = entry.product.itemCode;

    await ref.read(shoppingListControllerProvider).remove(itemCode);
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      'Removed ${entry.product.name}',
      actionLabel: premiseCode != null ? 'Undo' : null,
      onAction: premiseCode != null
          ? () => ref.read(shoppingListControllerProvider).restore(itemCode, premiseCode, quantity)
          : null,
    );
  }

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

          // Group by the store chosen for each item; entries with no
          // resolved price at all (rare — no price data anywhere) fall
          // into a catch-all group rather than being dropped silently.
          final groupOrder = <String>[];
          final groups = <String, List<ShoppingListEntry>>{};
          final groupStoreName = <String, String>{};
          for (final entry in entries) {
            final key = entry.price?.premiseCode ?? '_unavailable';
            if (!groups.containsKey(key)) {
              groupOrder.add(key);
              groups[key] = [];
              groupStoreName[key] = entry.storeName ?? 'Price unavailable';
            }
            groups[key]!.add(entry);
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const _CheapestStoreCard(),
                    for (final key in groupOrder) ...[
                      _StoreGroupHeader(
                        storeName: groupStoreName[key]!,
                        subtotal: groups[key]!.fold<double>(0, (sum, e) => sum + (e.subtotal ?? 0)),
                      ),
                      const SizedBox(height: 8),
                      for (final entry in groups[key]!) ...[
                        Dismissible(
                          key: ValueKey(entry.product.itemCode),
                          direction: DismissDirection.endToStart,
                          background: const _SwipeToDeleteBackground(),
                          onDismissed: (_) => _removeWithUndo(context, ref, entry),
                          child: CartItemTile(
                            entry: entry,
                            onOpen: () => context.push('/product/${entry.product.itemCode}'),
                            onQuantityChanged: (qty) => ref
                                .read(shoppingListControllerProvider)
                                .setQuantity(entry.product.itemCode, qty),
                            onRemove: () => _removeWithUndo(context, ref, entry),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ],
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

class _SwipeToDeleteBackground extends StatelessWidget {
  const _SwipeToDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }
}

class _StoreGroupHeader extends StatelessWidget {
  const _StoreGroupHeader({required this.storeName, required this.subtotal});

  final String storeName;
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'RM${subtotal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

/// Compares buying every cart item from a single store, for each store
/// already represented in the cart — spec-scoped to just those stores
/// (x, y, z), not the whole dataset.
class _CheapestStoreCard extends ConsumerWidget {
  const _CheapestStoreCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optionsAsync = ref.watch(singleStoreTotalsProvider);
    final options = optionsAsync.value ?? const [];

    // Nothing to compare when the cart only touches one store (or none).
    if (options.isEmpty) return const SizedBox.shrink();

    final cheapest = options.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storefront, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Cheapest Single Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'If you bought everything from one store instead:',
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 10),
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.missingItemCount > 0
                          ? '${option.storeName} (${option.missingItemCount} item'
                              '${option.missingItemCount > 1 ? 's' : ''} unavailable)'
                          : option.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RM${option.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: option == cheapest ? AppColors.primary : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
        ],
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
