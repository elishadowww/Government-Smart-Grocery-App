import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../models/price.dart';
import '../../../models/supermarket.dart';
import '../../../providers/price_provider.dart';
import '../../product_search/widgets/comparison_card.dart';

/// Bottom sheet letting the user pick which store to buy a product from —
/// so "Add to Cart" reflects a real choice instead of silently assuming
/// the cheapest option. Returns the selected [Price] (its `premiseCode` is
/// the chosen store), or null if the sheet was dismissed without a pick.
Future<Price?> showStorePickerSheet(
  BuildContext context, {
  required String itemCode,
  required String productName,
}) {
  return showModalBottomSheet<Price>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _StorePickerSheet(itemCode: itemCode, productName: productName),
  );
}

class _StorePickerSheet extends ConsumerWidget {
  const _StorePickerSheet({required this.itemCode, required this.productName});

  final String itemCode;
  final String productName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(latestPricesForItemProvider(itemCode));
    final storesAsync = ref.watch(priceComparisonStoresProvider(itemCode));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Choose a Store', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.grey),
              ),
              const SizedBox(height: 16),
              Flexible(child: _buildBody(pricesAsync, storesAsync)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<Price>> pricesAsync, AsyncValue<List<Supermarket>> storesAsync) {
    if (pricesAsync.isLoading || storesAsync.isLoading) {
      return const SkeletonListLoader(itemCount: 3);
    }
    if (pricesAsync.hasError || storesAsync.hasError) {
      return const InlineError(message: 'Could not load store options for this product.');
    }

    final prices = pricesAsync.value ?? const [];
    final stores = storesAsync.value ?? const [];
    if (prices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No store currently has a price for this product.',
          style: TextStyle(color: AppColors.grey),
        ),
      );
    }

    final storeByCode = {for (final s in stores) s.premiseCode: s};
    final cheapestPremiseCode = prices.first.premiseCode;

    return ListView.separated(
      shrinkWrap: true,
      itemCount: prices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final price = prices[index];
        final store = storeByCode[price.premiseCode];
        if (store == null) return const SizedBox.shrink();
        return ComparisonRow(
          supermarket: store,
          price: price.price,
          isCheapest: price.premiseCode == cheapestPremiseCode,
          distanceKm: null,
          onTap: () => Navigator.of(context).pop(price),
        );
      },
    );
  }
}
