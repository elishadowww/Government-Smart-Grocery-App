import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/cart_app_bar_action.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../models/price.dart';
import '../../../models/supermarket.dart';
import '../../../providers/price_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../../providers/store_distance_provider.dart';
import '../widgets/comparison_card.dart';
import '../../../core/localization/app_strings.dart';

enum _ComparisonSort { price, distance, alphabetical }

/// Price comparison screen (spec Fig 7.3.3): Lowest/Average/Highest stats,
/// sortable store list with real distance. Tapping a store adds this
/// product to the cart at that specific store — the full store list is
/// already on screen, so there's no need for a second store-picker sheet
/// like the quicker "Add to Cart" entry points elsewhere use.
class PriceComparisonScreen extends ConsumerStatefulWidget {
  const PriceComparisonScreen({super.key, required this.itemCode});

  final String itemCode;

  @override
  ConsumerState<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends ConsumerState<PriceComparisonScreen> {
  _ComparisonSort _sortBy = _ComparisonSort.price;

  Future<void> _addToCartAt(String premiseCode) async {
    final added = await addToShoppingListAt(ref, widget.itemCode, premiseCode);
    if (!mounted) return;
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
    final pricesAsync = ref.watch(latestPricesForItemProvider(widget.itemCode));
    final storesAsync = ref.watch(priceComparisonStoresProvider(widget.itemCode));

    final title = productAsync.value != null
        ? '${ref.tr('compare_prices')} — ${productAsync.value!.name}'
        : ref.tr('compare_prices');

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: const [CartAppBarAction()]),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: _buildBody(pricesAsync, storesAsync),
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<Price>> pricesAsync, AsyncValue<List<Supermarket>> storesAsync) {
    if (pricesAsync.isLoading || storesAsync.isLoading) {
      return const SkeletonListLoader();
    }

    if (pricesAsync.hasError) {
      return InlineError(
        message: ref.tr('could_not_load_prices'),
        onRetry: () => ref.invalidate(latestPricesForItemProvider(widget.itemCode)),
      );
    }
    if (storesAsync.hasError) {
      return InlineError(
        message: ref.tr('could_not_load_supermarkets'),
        onRetry: () => ref.invalidate(priceComparisonStoresProvider(widget.itemCode)),
      );
    }

    final prices = pricesAsync.value ?? const [];
    final stores = storesAsync.value ?? const [];

    if (prices.isEmpty) {
      return AppEmptyState(
        icon: Icons.price_check,
        message: ref.tr('no_price_data'),
      );
    }

    final storeByCode = {for (final s in stores) s.premiseCode: s};
    final cheapestPremiseCode = prices.first.premiseCode;

    final values = prices.map((p) => p.price).toList();
    final lowest = values.reduce((a, b) => a < b ? a : b);
    final highest = values.reduce((a, b) => a > b ? a : b);
    final average = values.reduce((a, b) => a + b) / values.length;

    final sorted = List<Price>.from(prices);
    switch (_sortBy) {
      case _ComparisonSort.price:
        break; // already ascending from the repository
      case _ComparisonSort.alphabetical:
        sorted.sort((a, b) => (storeByCode[a.premiseCode]?.name ?? '')
            .compareTo(storeByCode[b.premiseCode]?.name ?? ''));
        break;
      case _ComparisonSort.distance:
        break; // resolved live per-row below via Consumer; see _DistanceSortedList
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatsRow(lowest: lowest, average: average, highest: highest),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(ref.tr('sort'), style: TextStyle(color: AppColors.grey)),
            const SizedBox(width: 8),
            DropdownButton<_ComparisonSort>(
              value: _sortBy,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: _ComparisonSort.price, child: Text(ref.tr('sort_price'))),
                DropdownMenuItem(value: _ComparisonSort.distance, child: Text(ref.tr('sort_distance'))),
                DropdownMenuItem(value: _ComparisonSort.alphabetical, child: Text(ref.tr('sort_alphabetical'))),
              ],
              onChanged: (value) => setState(() => _sortBy = value ?? _ComparisonSort.price),
            ),
            const Spacer(),
            Text(ref.tr('tap_store_to_add'), style: TextStyle(color: AppColors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _sortBy == _ComparisonSort.distance
              ? _DistanceSortedList(
                  prices: sorted,
                  storeByCode: storeByCode,
                  cheapestPremiseCode: cheapestPremiseCode,
                  onAdd: _addToCartAt,
                )
              : ListView.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final price = sorted[index];
                    final store = storeByCode[price.premiseCode];
                    if (store == null) return const SizedBox.shrink();
                    return Consumer(
                      builder: (context, ref, _) {
                        final distanceAsync = ref.watch(storeDistanceKmProvider(store));
                        return ComparisonRow(
                          supermarket: store,
                          price: price.price,
                          isCheapest: price.premiseCode == cheapestPremiseCode,
                          distanceKm: distanceAsync.value,
                          distanceLoading: distanceAsync.isLoading,
                          onTap: () => _addToCartAt(store.premiseCode),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.lowest, required this.average, required this.highest});

  final double lowest;
  final double average;
  final double highest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _StatColumn(label: ref.tr('lowest'), value: lowest, color: AppColors.primary)),
          Expanded(child: _StatColumn(label: ref.tr('average'), value: average, color: AppColors.text)),
          Expanded(child: _StatColumn(label: ref.tr('highest'), value: highest, color: AppColors.error)),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
        const SizedBox(height: 4),
        Text(
          'RM${value.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

/// Resolves every visible store's distance before sorting — distance can't
/// be sorted incrementally like Price/Alphabetical since it depends on an
/// async geocode per store.
class _DistanceSortedList extends ConsumerWidget {
  const _DistanceSortedList({
    required this.prices,
    required this.storeByCode,
    required this.cheapestPremiseCode,
    required this.onAdd,
  });

  final List<Price> prices;
  final Map<String, Supermarket> storeByCode;
  final String cheapestPremiseCode;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = prices
        .map((p) => (price: p, store: storeByCode[p.premiseCode]))
        .where((e) => e.store != null)
        .toList();

    final distanceResults = [
      for (final e in entries) ref.watch(storeDistanceKmProvider(e.store!)),
    ];

    if (distanceResults.any((d) => d.isLoading)) {
      return const SkeletonListLoader();
    }

    final sortedIndexes = List<int>.generate(entries.length, (i) => i)
      ..sort((i, j) {
        final da = distanceResults[i].value;
        final db = distanceResults[j].value;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    return ListView.separated(
      itemCount: sortedIndexes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, position) {
        final index = sortedIndexes[position];
        final entry = entries[index];
        return ComparisonRow(
          supermarket: entry.store!,
          price: entry.price.price,
          isCheapest: entry.price.premiseCode == cheapestPremiseCode,
          distanceKm: distanceResults[index].value,
          onTap: () => onAdd(entry.store!.premiseCode),
        );
      },
    );
  }
}
