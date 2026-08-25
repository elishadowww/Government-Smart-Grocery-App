import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/budget_card.dart';
import '../../../core/widgets/cart_app_bar_action.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/price_provider.dart';
import '../../../providers/recent_product_provider.dart';
import '../widgets/app_drawer.dart';
import '../../../core/localization/app_strings.dart';

/// Dashboard (spec Fig 7.1.1): landing screen and navigation hub. Search,
/// Nearby, Cart, Favourites, Notifications and Budget are wired to real
/// screens; Price Trends is out of this branch's scope and shows a
/// placeholder. The "Nearby Cheapest Supermarket" card is omitted since
/// PriceCatcher stores have no coordinates to rank by proximity without a
/// live location fix per item.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('app_name')),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_none),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          const CartAppBarAction(),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSearchBar(
            controller: TextEditingController(),
            hintText: ref.tr('search_products'),
            readOnly: true,
            onTap: () => context.push('/search'),
          ),
          const SizedBox(height: 20),
          Text(ref.tr('quick_actions'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.search,
                  label: ref.tr('search'),
                  onTap: () => context.push('/search'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.storefront_outlined,
                  label: ref.tr('nearby'),
                  onTap: () => context.push('/nearby'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.shopping_cart_outlined,
                  label: ref.tr('cart'),
                  onTap: () => context.push('/cart'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.trending_up,
                  label: ref.tr('trends'),
                  onTap: () => context.push('/price_trends'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const BudgetCard(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ref.tr('price_alerts'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Text( ref.tr('view_all'), style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PriceAlertsPreview(),
          const SizedBox(height: 24),
          Text(ref.tr('recent_products'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          const _RecentProducts(),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceAlertsPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider).value ?? const [];

    if (notifications.isEmpty) {
      return AppEmptyState(icon: Icons.notifications_none, message: ref.tr('no_price_alerts'),);
    }

    return Column(
      children: [
        for (final notification in notifications.take(2))
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${notification.title}: ${notification.message}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentProducts extends ConsumerWidget {
  const _RecentProducts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(recentProductsProvider);
    final products = productsAsync.value ?? const [];

    if (products.isEmpty) {
      return AppEmptyState(icon: Icons.history, message: ref.tr('no_recent_products'),);
    }

    final itemCodes = products.map((p) => p.itemCode).toList();
    final priceMap = ref.watch(cheapestPricesProvider(itemCodes)).value ?? const {};

    return Column(
      children: [
        for (final product in products)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/product/${product.itemCode}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        priceMap[product.itemCode] == null
                            ? '—'
                            : 'RM${priceMap[product.itemCode]!.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
