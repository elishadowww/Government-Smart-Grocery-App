import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/cart_app_bar_action.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../models/price.dart';
import '../../../providers/current_user_provider.dart';
import '../../../providers/price_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/recent_product_provider.dart';
import '../../../providers/saved_product_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../cart/widgets/store_picker_sheet.dart';
import '../widgets/comparison_card.dart';
import '../../../core/localization/app_strings.dart';

enum _PriceTrend { rising, falling, stable }

/// Product detail screen (product_detail_screen.png), adapted to what the
/// PriceCatcher dataset actually has: no ratings/reviews/Best-Seller badge
/// or stock status (not in the dataset), but a real price-trend, real
/// cheapest/average price, and a real mini price-comparison list.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.itemCode});

  final String itemCode;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _addingToCart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      recordProductView(ref, widget.itemCode);
    });
  }

  Future<void> _toggleSave() async {
    final isRegistered = ref.read(isRegisteredProvider);
    if (!isRegistered) {
      await showLoginRequiredDialog(context);
      return;
    }

    final isSaved = await ref.read(isProductSavedProvider(widget.itemCode).future);
    final controller = ref.read(savedProductsControllerProvider);
    if (isSaved) {
      await controller.unsave(widget.itemCode);
      if (mounted) showAppSnackBar(context, ref.tr('removed_from_favourites'));
    } else {
      await controller.save(widget.itemCode);
      if (mounted) showAppSnackBar(context, ref.tr('added_to_favourites'));
    }
  }

  Future<void> _addToCart() async {
    final productName = ref.read(productByIdProvider(widget.itemCode)).value?.name ?? '';
    final selected = await showStorePickerSheet(
      context,
      itemCode: widget.itemCode,
      productName: productName,
    );
    if (selected == null || !mounted) return;

    setState(() => _addingToCart = true);
    final added = await addToShoppingListAt(ref, widget.itemCode, selected.premiseCode);
    if (!mounted) return;
    setState(() => _addingToCart = false);
    showAppSnackBar(
      context,
      added ? ref.tr('added_to_cart') : ref.tr('please_try_again'),
      isError: !added,
      actionLabel: added ? ref.tr('view') : null,
      onAction: added ? () => context.push('/cart') : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.itemCode));
    final isSavedAsync = ref.watch(isProductSavedProvider(widget.itemCode));

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('product_details')),
        actions: [
          IconButton(
            icon: Icon(
              (isSavedAsync.value ?? false) ? Icons.favorite : Icons.favorite_border,
              color: (isSavedAsync.value ?? false) ? AppColors.error : null,
            ),
            tooltip: (isSavedAsync.value ?? false)
                ? ref.tr('remove_from_favourites')
                : ref.tr('add_to_favourites'),
            onPressed: _toggleSave,
          ),
          const CartAppBarAction(),
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return InlineError(message: ref.tr('product_not_found'));
          }
          return _ProductDetailBody(
            itemCode: widget.itemCode,
            productName: product.name,
            category: product.itemCategory,
            itemGroup: product.itemGroup,
            unit: product.unit,
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => InlineError(
          message: ref.tr('could_not_load_product'),
          onRetry: () => ref.invalidate(productByIdProvider(widget.itemCode)),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: AppButton(
          label: ref.tr('add_to_cart'),
          icon: Icons.shopping_cart_outlined,
          loading: _addingToCart,
          onPressed: _addToCart,
        ),
      ),
    );
  }
}

class _ProductDetailBody extends ConsumerWidget {
  const _ProductDetailBody({
    required this.itemCode,
    required this.productName,
    required this.category,
    required this.itemGroup,
    required this.unit,
  });

  final String itemCode;
  final String productName;
  final String category;
  final String itemGroup;
  final String unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(latestPricesForItemProvider(itemCode));
    final storesAsync = ref.watch(priceComparisonStoresProvider(itemCode));
    final historyAsync = ref.watch(priceHistoryProvider(PriceHistoryQuery(itemCode: itemCode)));

    if (pricesAsync.isLoading || storesAsync.isLoading) {
      return const AppLoading();
    }
    if (pricesAsync.hasError || storesAsync.hasError) {
      return InlineError(
        message: ref.tr('could_not_load_pricing'),
        onRetry: () {
          ref.invalidate(latestPricesForItemProvider(itemCode));
          ref.invalidate(priceComparisonStoresProvider(itemCode));
        },
      );
    }

    final prices = pricesAsync.value ?? const <Price>[];
    final stores = storesAsync.value ?? const [];
    final storeByCode = {for (final s in stores) s.premiseCode: s};

    if (prices.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text(ref.tr('no_price_data'))),
      );
    }

    final cheapest = prices.first;
    final cheapestStore = storeByCode[cheapest.premiseCode];
    final average = prices.map((p) => p.price).reduce((a, b) => a + b) / prices.length;
    final trend = _computeTrend(historyAsync.value);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(categoryIcon(category), size: 48, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(category, style: const TextStyle(color: AppColors.grey)),
                    const SizedBox(height: 10),
                    Text(
                      'RM${cheapest.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      ref.tr('price_varies_by_store'),
                      style: TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.storefront_outlined,
                    label: ref.tr('cheapest_at'),
                    value: cheapestStore?.name ?? '—',
                    valueColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: Icons.sell_outlined,
                    label: ref.tr('avg_price'),
                    value: 'RM${average.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: trend == _PriceTrend.rising
                        ? Icons.trending_up
                        : trend == _PriceTrend.falling
                            ? Icons.trending_down
                            : Icons.trending_flat,
                    label: ref.tr('price_trend'),
                    value: switch (trend) {
                      _PriceTrend.rising => 'Rising',
                      _PriceTrend.falling => 'Falling',
                      _PriceTrend.stable => 'Stable',
                    },
                    valueColor: trend == _PriceTrend.rising ? AppColors.error : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ref.tr('price_comparison'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () => context.push('/compare/$itemCode'),
                child: Row(
                  children: [
                    Text(ref.tr('view_all_stores'),
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final price in prices.take(3))
            if (storeByCode[price.premiseCode] != null) ...[
              ComparisonRow(
                supermarket: storeByCode[price.premiseCode]!,
                price: price.price,
                isCheapest: price.premiseCode == cheapest.premiseCode,
                distanceKm: null,
                onTap: () => context.push('/compare/$itemCode'),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 14),
          Text(ref.tr('product_information'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _InfoRow(label: ref.tr('category'), value: category),
                _InfoRow(label: ref.tr('item_group'), value: itemGroup),
                _InfoRow(label: ref.tr('unit'), value: unit, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  _PriceTrend _computeTrend(List<Price>? history) {
    if (history == null || history.length < 2) return _PriceTrend.stable;
    final first = history.first.price;
    final last = history.last.price;
    if (first == 0) return _PriceTrend.stable;
    final change = (last - first) / first;
    if (change.abs() < 0.01) return _PriceTrend.stable;
    return change > 0 ? _PriceTrend.rising : _PriceTrend.falling;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.text,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.grey, size: 20),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 13),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.grey)),
          Text(value.isEmpty ? '—' : value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
