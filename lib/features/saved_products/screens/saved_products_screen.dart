import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
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
import '../../../providers/saved_product_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../../providers/supermarket_provider.dart';
import '../widgets/saved_product_tile.dart';

/// Favourites screen (saved_product_screen.png): banner, search-within-
/// favourites, count + Edit, favourited product rows. Guests are prompted
/// to log in rather than shown an empty list (spec §4: saving is
/// registered-only). Backed by the same saved-product data layer as before
/// ("Favourites" is a UI rebrand, not a new store).
class SavedProductsScreen extends ConsumerStatefulWidget {
  const SavedProductsScreen({super.key});

  @override
  ConsumerState<SavedProductsScreen> createState() => _SavedProductsScreenState();
}

class _SavedProductsScreenState extends ConsumerState<SavedProductsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _editing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _unsave(Product product) async {
    await ref.read(savedProductsControllerProvider).unsave(product.itemCode);
    if (mounted) showAppSnackBar(context, 'Removed from favourites');
  }

  Future<void> _addToCart(Product product) async {
    final added = await addToShoppingList(ref, product.itemCode);
    if (!mounted) return;
    showAppSnackBar(
      context,
      added ? 'Added to cart' : 'Please try again',
      isError: !added,
      actionLabel: added ? 'View' : null,
      onAction: added ? () => context.push('/cart') : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRegistered = ref.watch(isRegisteredProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites'),
        actions: [
          const CartAppBarAction(),
          if (isRegistered)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Clear All Favourites',
                  message: 'This will remove every favourited product. This cannot be undone.',
                );
                if (confirmed == true) {
                  final saved = await ref.read(savedProductsProvider.future);
                  final controller = ref.read(savedProductsControllerProvider);
                  for (final product in saved) {
                    await controller.unsave(product.itemCode);
                  }
                }
              },
            ),
        ],
      ),
      body: isRegistered ? _buildSavedList() : _buildLoginPrompt(),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 56, color: AppColors.grey),
            const SizedBox(height: 16),
            const Text(
              'Log in to save favourites',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Favourite products you love and get notified when their price changes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Login',
              expand: false,
              onPressed: () => context.push('/login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedList() {
    final savedAsync = ref.watch(savedProductsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Favourites', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text(
                        'Quick access to products you save for later.',
                        style: TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.shopping_basket, color: AppColors.primary, size: 32),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppSearchBar(
            controller: _searchController,
            hintText: 'Search favourites...',
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: savedAsync.when(
              data: (products) {
                final filtered = _query.isEmpty
                    ? products
                    : products
                        .where((p) => p.name.toLowerCase().contains(_query))
                        .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (products.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('All Favourites (${products.length})',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          GestureDetector(
                            onTap: () => setState(() => _editing = !_editing),
                            child: Text(
                              _editing ? 'Done' : 'Edit',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? AppEmptyState(
                              icon: Icons.favorite_border,
                              message: products.isEmpty
                                  ? 'You haven\'t added any favourites yet.'
                                  : 'No favourites match your search.',
                            )
                          : _SavedProductListView(
                              products: filtered,
                              editing: _editing,
                              onUnsave: _unsave,
                              onAddToCart: _addToCart,
                            ),
                    ),
                  ],
                );
              },
              loading: () => const SkeletonListLoader(),
              error: (e, _) => InlineError(
                message: 'Could not load your favourites.',
                onRetry: () => ref.invalidate(savedProductsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedProductListView extends ConsumerWidget {
  const _SavedProductListView({
    required this.products,
    required this.editing,
    required this.onUnsave,
    required this.onAddToCart,
  });

  final List<Product> products;
  final bool editing;
  final ValueChanged<Product> onUnsave;
  final ValueChanged<Product> onAddToCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCodes = products.map((p) => p.itemCode).toList();
    final pricesAsync = ref.watch(cheapestPricesProvider(itemCodes));
    final priceMap = pricesAsync.value ?? const {};

    final premiseCodes = {
      for (final price in priceMap.values) price.premiseCode,
    }.toList();
    final storesAsync = ref.watch(supermarketByIdsProvider(premiseCodes));
    final storeByCode = {for (final s in storesAsync.value ?? const []) s.premiseCode: s.name};

    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = products[index];
        final price = priceMap[product.itemCode];
        return editing
            ? _EditableRow(
                product: product,
                price: price?.price,
                storeName: price == null ? null : storeByCode[price.premiseCode],
                onRemove: () => onUnsave(product),
                onOpen: () => context.push('/product/${product.itemCode}'),
              )
            : SavedProductTile(
                product: product,
                price: price?.price,
                storeName: price == null ? null : storeByCode[price.premiseCode],
                onOpen: () => context.push('/product/${product.itemCode}'),
                onUnsave: () => onUnsave(product),
                onAddToCart: () => onAddToCart(product),
              );
      },
    );
  }
}

class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.product,
    required this.price,
    required this.storeName,
    required this.onRemove,
    required this.onOpen,
  });

  final Product product;
  final double? price;
  final String? storeName;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle, color: AppColors.error),
            onPressed: onRemove,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    price == null ? 'Price unavailable' : 'RM${price!.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
