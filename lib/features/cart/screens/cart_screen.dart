import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../providers/shopping_provider.dart';
import '../widgets/cart_item_tile.dart';

/// Cart screen (spec §7.5). Reachable from the persistent cart icon in the
/// app bar, the Dashboard's "Cart" quick action, the nav drawer, and a
/// "View" action on the "Added to cart" snackbar.
///
/// Items are grouped by the store the user chose for each one (spec-driven
/// addition: Add to Cart now asks which store, rather than assuming
/// cheapest). A "Cheapest Single Store" card compares the total of buying
/// everything from just one store, scoped to the handful of stores already
/// touched by the cart — not a nationwide scan. A "Mixed-Store Total" card
/// (spec §7.5) recommends buying each item from whichever store has the
/// cheapest price for it, when that per-item optimization actually beats
/// the best single-store total.
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
      ref.tr('removed_item').replaceAll('{name}', entry.product.name),
      actionLabel: premiseCode != null ? ref.tr('undo') : null,
      onAction: premiseCode != null
          ? () => ref.read(shoppingListControllerProvider).restore(itemCode, premiseCode, quantity)
          : null,
    );
  }

  /// Finishes the shopping trip: confirms, then clears the cart. There's no
  /// purchase-history archive to write to (that's the rest of Module 3),
  /// so "completing" a trip is just closing out the cart it was built in.
  Future<void> _completeShopping(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: ref.tr('complete_shopping'),
      message: ref.tr('complete_shopping_message'),
      confirmLabel: ref.tr('complete_shopping'),
    );
    if (confirmed != true) return;

    await ref.read(shoppingListControllerProvider).clearAll();
    if (!context.mounted) return;

    showAppSnackBar(context, ref.tr('shopping_completed'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(shoppingListEntriesProvider);
    final total = ref.watch(shoppingListTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('cart')),
        actions: [
          if ((entriesAsync.value ?? const []).isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: ref.tr('clear_cart'),
                  message: ref.tr('clear_cart_message'),
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
              message: ref.tr('empty_cart_message'),
              actionLabel: ref.tr('search_products'),
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
              groupStoreName[key] = entry.storeName ?? ref.tr('price_unavailable');
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
                    const _MixedStoreTotalCard(),
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
              _TotalBar(
                total: total,
                onCompleteShopping: () => _completeShopping(context, ref),
              ),
            ],
          );
        },
        loading: () => const SkeletonListLoader(),
        error: (e, _) => InlineError(
          message: ref.tr('could_not_load_cart'),
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
          Row(
            children: [
              Icon(Icons.storefront, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(ref.tr('cheapest_single_store'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ref.tr('single_store_comparison_subtitle'),
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
                          ? ref
                          .tr(option.missingItemCount == 1
                          ? 'store_missing_items_singular'
                          : 'store_missing_items_plural')
                          .replaceAll('{store}', option.storeName)
                          .replaceAll('{count}', '${option.missingItemCount}')
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

/// Spec §7.5's "Mixed-Store Total": recommends buying each cart item from
/// whichever store has the cheapest price for it, shown only when that
/// per-item optimization actually beats the best single-store total.
class _MixedStoreTotalCard extends ConsumerWidget {
  const _MixedStoreTotalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixed = ref.watch(mixedStoreTotalProvider).value;
    if (mixed == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.call_split, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                ref.tr('mixed_store_total'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ref
                .tr('mixed_store_total_subtitle')
                .replaceAll('{count}', '${mixed.storeCount}'),
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ref.tr('mixed_store_savings').replaceAll('{amount}', mixed.savings.toStringAsFixed(2)),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              Text(
                'RM${mixed.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalBar extends ConsumerWidget {
  const _TotalBar({required this.total, required this.onCompleteShopping});

  final double total;
  final VoidCallback onCompleteShopping;

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ref.tr('total_cost'), style: TextStyle(fontSize: 15, color: AppColors.grey)),
              Text(
                'RM${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            label: ref.tr('complete_shopping'),
            icon: Icons.check_circle_outline,
            onPressed: onCompleteShopping,
          ),
        ],
      ),
    );
  }
}
