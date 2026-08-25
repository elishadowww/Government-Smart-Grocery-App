import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';

enum ProductSortBy { price, distance, alphabetical }

/// Search Products filter state (spec Fig 7.3.2).
class ProductFilter {
  const ProductFilter({
    this.category,
    this.minPrice = 0,
    this.maxPrice = 50,
    this.sortBy = ProductSortBy.price,
  });

  final String? category;
  final double minPrice;
  final double maxPrice;
  final ProductSortBy sortBy;

  bool get isDefault =>
      category == null && minPrice == 0 && maxPrice == 50 && sortBy == ProductSortBy.price;

  ProductFilter copyWith({
    String? category,
    bool clearCategory = false,
    double? minPrice,
    double? maxPrice,
    ProductSortBy? sortBy,
  }) {
    return ProductFilter(
      category: clearCategory ? null : (category ?? this.category),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// Filter bottom sheet matching filter_product_widget.png: Category
/// dropdown, Price Range slider, Sort By (Price/Distance/Alphabetical),
/// Reset/Apply.
class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.categories,
    required this.onApply,
    this.maxPriceBound = 50,
  });

  final ProductFilter initialFilter;
  final List<String> categories;
  final ValueChanged<ProductFilter> onApply;
  final double maxPriceBound;

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late String? _category = widget.initialFilter.category;
  late RangeValues _priceRange = RangeValues(
    widget.initialFilter.minPrice,
    widget.initialFilter.maxPrice,
  );
  late ProductSortBy _sortBy = widget.initialFilter.sortBy;

  void _reset() {
    setState(() {
      _category = null;
      _priceRange = RangeValues(0, widget.maxPriceBound);
      _sortBy = ProductSortBy.price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
             Center(
              child: Text(ref.tr('filter'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            Text(ref.tr('category'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _category,
              icon: const Icon(Icons.keyboard_arrow_down),
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(ref.tr('all_categories'))),
                for (final category in widget.categories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 20),

            Text(ref.tr('price_range'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RM${_priceRange.start.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                Text('RM${_priceRange.end.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 12)),
              ],
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: widget.maxPriceBound,
              divisions: widget.maxPriceBound.round().clamp(1, 100).toInt(),
              activeColor: AppColors.primary,
              labels: RangeLabels(
                'RM${_priceRange.start.toStringAsFixed(0)}',
                'RM${_priceRange.end.toStringAsFixed(0)}',
              ),
              onChanged: (values) => setState(() => _priceRange = values),
            ),
            const SizedBox(height: 12),

            Text(ref.tr('sort_by'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            _SortOption(
              label: ref.tr('sort_price'),
              value: ProductSortBy.price,
              groupValue: _sortBy,
              onChanged: (v) => setState(() => _sortBy = v),
            ),
            _SortOption(
              label: ref.tr('sort_distance'),
              value: ProductSortBy.distance,
              groupValue: _sortBy,
              onChanged: (v) => setState(() => _sortBy = v),
            ),
            _SortOption(
              label: ref.tr('sort_alphabetical'),
              value: ProductSortBy.alphabetical,
              groupValue: _sortBy,
              onChanged: (v) => setState(() => _sortBy = v),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: ref.tr('reset'),
                    type: AppButtonType.outlined,
                    icon: Icons.refresh,
                    onPressed: _reset,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: ref.tr('apply'),
                    type: AppButtonType.filled,
                    icon: Icons.filter_alt,
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onApply(
                        ProductFilter(
                          category: _category,
                          minPrice: _priceRange.start,
                          maxPrice: _priceRange.end,
                          sortBy: _sortBy,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final ProductSortBy value;
  final ProductSortBy groupValue;
  final ValueChanged<ProductSortBy> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ProductSortBy>(
      value: value,
      groupValue: groupValue,
      onChanged: (v) => onChanged(v!),
      title: Text(label),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
