import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/search_aliases.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/cart_app_bar_action.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../models/product.dart';
import '../../../providers/current_user_provider.dart';
import '../../../providers/price_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/recent_search_provider.dart';
import '../../../providers/saved_product_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../../providers/store_distance_provider.dart';
import '../../../providers/supermarket_provider.dart';
import '../../cart/widgets/store_picker_sheet.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/product_list.dart';
import '../widgets/search_suggestion.dart';
import '../../../providers/search_query_provider.dart';
import '../../../core/localization/app_strings.dart';

/// Search Products screen (spec §7.3 / search_product_screen.png): search
/// bar, recent searches, filter + results row, product cards.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  ProductFilter _filter = const ProductFilter();
  List<ProductSearchResult>? _results;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _search();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingQuery = ref.read(activeSearchQueryProvider);

      if (pendingQuery.isNotEmpty) {
        _controller.text = pendingQuery; // 1. Pre-fill search field
        _search(); // 2. Trigger search query execution
        ref.read(activeSearchQueryProvider.notifier).clear(); // 3. Clear provider state
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _onSubmitted(String value) async {
    if (value.trim().isNotEmpty) {
      await ref.read(recentSearchesControllerProvider).record(value.trim());
    }
    _search();
  }

  Future<void> _selectRecentSearch(String term) async {
    _controller.text = term;
    await ref.read(recentSearchesControllerProvider).record(term);
    _search();
  }

  Future<void> _clearRecentSearches() async {
    final confirmed = await showConfirmDialog(
      context,
      title: ref.tr('clear_recent_searches_title'),
      message: ref.tr('clear_recent_searches_message'),
    );
    if (confirmed == true) {
      await ref.read(recentSearchesControllerProvider).clearAll();
    }
  }

  Future<void> _openFilter() async {
    final categories = await ref.read(productCategoriesProvider.future);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(
        initialFilter: _filter,
        categories: categories,
        onApply: (filter) {
          setState(() => _filter = filter);
          _search();
        },
      ),
    );
  }

  void _browseCategory(String category) {
    setState(() => _filter = _filter.copyWith(category: category));
    _search();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty && _filter.category == null) {
      setState(() {
        _results = null;
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final productRepo = ref.read(productRepositoryProvider);
      final priceRepo = ref.read(priceRepositoryProvider);
      final supermarketRepo = ref.read(supermarketRepositoryProvider);

      final products = await productRepo.search(
        terms: expandSearchTerms(query),
        category: _filter.category,
      );

      if (products.isEmpty) {
        if (!mounted) return;
        setState(() {
          _results = [];
          _loading = false;
        });
        return;
      }

      final itemCodes = products.map((p) => p.itemCode).toList();
      final priceMap = await priceRepo.getCheapestPrices(itemCodes);

      var rows = [
        for (final product in products)
          ProductSearchResult(product: product, price: priceMap[product.itemCode]),
      ];

      rows = rows
          .where((r) =>
              r.price == null ||
              (r.price!.price >= _filter.minPrice && r.price!.price <= _filter.maxPrice))
          .toList();

      final premiseCodes = {
        for (final r in rows)
          if (r.price != null) r.price!.premiseCode,
      }.toList();
      final stores = await supermarketRepo.getByIds(premiseCodes);
      final storeByCode = {for (final s in stores) s.premiseCode: s};

      switch (_filter.sortBy) {
        case ProductSortBy.alphabetical:
          rows.sort((a, b) => a.product.name.compareTo(b.product.name));
          break;
        case ProductSortBy.price:
          rows.sort(_byNullableAsc((r) => r.price?.price));
          break;
        case ProductSortBy.distance:
          final distanceByPremise = <String, double?>{};
          for (final code in premiseCodes) {
            final store = storeByCode[code];
            if (store == null) continue;
            distanceByPremise[code] =
                await ref.read(storeDistanceKmProvider(store).future);
          }
          rows.sort(_byNullableAsc(
            (r) => r.price == null ? null : distanceByPremise[r.price!.premiseCode],
          ));
          break;
      }

      rows = [
        for (final r in rows)
          ProductSearchResult(
            product: r.product,
            price: r.price,
            storeName: r.price == null ? null : storeByCode[r.price!.premiseCode]?.name,
          ),
      ];

      if (!mounted) return;
      setState(() {
        _results = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '${ref.tr('search_error')}\n$e';
        _loading = false;
      });
    }
  }

  int Function(ProductSearchResult, ProductSearchResult) _byNullableAsc(
    double? Function(ProductSearchResult) key,
  ) {
    return (a, b) {
      final ka = key(a);
      final kb = key(b);
      if (ka == null && kb == null) return 0;
      if (ka == null) return 1;
      if (kb == null) return -1;
      return ka.compareTo(kb);
    };
  }

  Future<void> _toggleSave(Product product) async {
    final isRegistered = ref.read(isRegisteredProvider);
    if (!isRegistered) {
      await showLoginRequiredDialog(context);
      return;
    }

    final savedCodes = await ref.read(savedItemCodesProvider.future);
    final controller = ref.read(savedProductsControllerProvider);
    final isSaved = savedCodes.contains(product.itemCode);

    if (isSaved) {
      await controller.unsave(product.itemCode);
      if (mounted) showAppSnackBar(context, ref.tr('removed_from_favourites'));
    } else {
      await controller.save(product.itemCode);
      if (mounted) showAppSnackBar(context, ref.tr('added_to_favourites'));
    }
  }

  Future<void> _addToCart(Product product) async {
    final selected = await showStorePickerSheet(
      context,
      itemCode: product.itemCode,
      productName: product.name,
    );
    if (selected == null || !mounted) return;

    final added = await addToShoppingListAt(ref, product.itemCode, selected.premiseCode);
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
    final recentSearches = ref.watch(recentSearchesProvider).value ?? const [];
    final savedItemCodes =
        (ref.watch(savedItemCodesProvider).value ?? const <String>[]).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('search_products_menu')),
        actions: const [CartAppBarAction()],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchBar(
              controller: _controller,
              hintText: ref.tr('search_products_hint'),
              onChanged: _onQueryChanged,
              onSubmitted: _onSubmitted,
              autofocus: widget.initialQuery == null,
            ),
            const SizedBox(height: 16),
            RecentSearches(
              terms: recentSearches,
              onSelect: _selectRecentSearch,
              onClearAll: _clearRecentSearches,
            ),
            if (recentSearches.isNotEmpty) const SizedBox(height: 16),
            Row(
              children: [
                InkWell(
                  onTap: _openFilter,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt_outlined,
                          size: 18,
                          color: _filter.isDefault ? AppColors.text : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ref.tr('filter'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _filter.isDefault ? AppColors.text : AppColors.primary,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 16, color: AppColors.divider),
                const SizedBox(width: 12),
                if (_results != null)
                  Text('${ref.tr('results')}: ${_results!.length}',
                      style: const TextStyle(color: AppColors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildResults(savedItemCodes)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(Set<String> savedItemCodes) {
    if (_loading) return const SkeletonListLoader();

    if (_error != null) {
      return InlineError(message: _error!, onRetry: _search);
    }

    if (_results == null) {
      return _CategoryBrowse(onSelect: _browseCategory);
    }

    if (_results!.isEmpty) {
      return AppEmptyState(
        message: ref.tr('no_products_found'),
        actionLabel: _filter.isDefault ? null : ref.tr('clear_filters'),
        onAction: _filter.isDefault
            ? null
            : () {
                setState(() => _filter = const ProductFilter());
                _search();
              },
      );
    }

    return ProductResultList(
      results: _results!,
      savedItemCodes: savedItemCodes,
      onOpenProduct: (p) => context.push('/product/${p.itemCode}'),
      onComparePrices: (p) => context.push('/compare/${p.itemCode}'),
      onToggleSave: _toggleSave,
      onAdd: _addToCart,
    );
  }
}

/// Shown before the user has searched or filtered anything, so the screen
/// isn't just a blank prompt — tapping a category browses it directly via
/// [ProductRepository.search]'s empty-query + category path.
class _CategoryBrowse extends ConsumerWidget {
  const _CategoryBrowse({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return AppEmptyState(
            icon: Icons.search,
            message: ref.tr('search_prompt'),
          );
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ref.tr('or_browse_category'),
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in categories)
                    ActionChip(
                      avatar: Icon(categoryIcon(category), size: 16, color: AppColors.primary),
                      label: Text(category),
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none,
                      ),
                      labelStyle: const TextStyle(fontSize: 12),
                      onPressed: () => onSelect(category),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SkeletonListLoader(),
      error: (e, _) => InlineError(
        message: ref.tr('could_not_load_categories'),
        onRetry: () => ref.invalidate(productCategoriesProvider),
      ),
    );
  }
}
