import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_strings.dart';

import '../../../providers/price_provider.dart';
import '../../../providers/supermarket_provider.dart';
import '../models/supermarket_model.dart';
import 'store_catalog_screen.dart';

/// Products & prices shown here are matched from this Places result to a
/// PriceCatcher premise by [SupermarketMatcher] — the two data sources
/// don't share an ID, so on a low-confidence match the UI says so instead
/// of presenting it as exact.
const _maxCatalogItems = 20;
const _maxSavingsItems = 5;

class SupermarketDetailScreen extends ConsumerWidget {
  final SupermarketModel supermarket;

  const SupermarketDetailScreen({
    super.key,
    required this.supermarket,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchedPremiseForPlaceProvider(supermarket));

    return Scaffold(
      appBar: AppBar(
        title: Text(supermarket.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Store Icon
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  supermarket.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),

                  const SizedBox(width: 5),

                  Text(
                    supermarket.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(width: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: supermarket.isOpen
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      supermarket.isOpen
                          ? ref.tr('open')
                          : ref.tr('closed'),
                      style: TextStyle(
                        color: supermarket.isOpen
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Text(
                ref.tr('address'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Icon(
                    Icons.location_on,
                    color: Colors.red,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      supermarket.address,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              const Divider(),

              const SizedBox(height: 10),

              Text(
                ref.tr('product_catalogue'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              matchAsync.when(
                data: (match) => match == null
                    ? _infoCard(
                        icon: Icons.shopping_bag,
                        title: ref.tr('no_product_data_title'),
                        subtitle: ref.tr('no_product_data_desc'),
                      )
                    : _StoreCatalogSection(
                        premiseCode: match.supermarket.premiseCode,
                        isApproximateMatch: match.isApproximate,
                        storeName: supermarket.name,
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => _infoCard(
                  icon: Icons.shopping_bag,
                  title: ref.tr('could_not_load_products'),
                  subtitle: ref.tr('check_connection_retry'),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                ref.tr('price_comparison'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              matchAsync.when(
                data: (match) => match == null
                    ? _infoCard(
                        icon: Icons.compare_arrows,
                        title: ref.tr('no_comparison_data_title'),
                        subtitle: ref.tr('no_comparison_data_desc'),
                      )
                    : _PriceSavingsSection(premiseCode: match.supermarket.premiseCode),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => _infoCard(
                  icon: Icons.compare_arrows,
                  title: ref.tr('could_not_load_comparison'),
                  subtitle: ref.tr('check_connection_retry'),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: Icon(
            icon,
            color: Colors.green,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

/// Product Catalogue: everything the matched premise stocks, capped so the
/// page doesn't try to render hundreds of rows inline.
class _StoreCatalogSection extends ConsumerWidget {
  const _StoreCatalogSection({
    required this.premiseCode,
    required this.isApproximateMatch,
    required this.storeName,
  });

  final String premiseCode;
  final bool isApproximateMatch;
  final String storeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(storeCatalogProvider(premiseCode));

    return catalogAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return SupermarketDetailScreen._infoCard(
            icon: Icons.shopping_bag,
            title: ref.tr('no_products_found'),
            subtitle: ref.tr('no_products_found_desc'),
          );
        }

        final shown = entries.take(_maxCatalogItems).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isApproximateMatch)
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  ref.tr('approximate_match_warning'),
                  style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                ),
              ),
            for (final entry in shown) ...[
              CatalogRow(entry: entry),
              const SizedBox(height: 10),
            ],
            if (entries.length > shown.length)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoreCatalogScreen(
                        premiseCode: premiseCode,
                        storeName: storeName,
                        isApproximateMatch: isApproximateMatch,
                      ),
                    ),
                  ),
                  child: Text(
                    ref.tr('view_all_products').replaceAll('{total}', '${entries.length}'),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => SupermarketDetailScreen._infoCard(
        icon: Icons.shopping_bag,
        title: ref.tr('could_not_load_products'),
        subtitle: ref.tr('check_connection_retry'),
      ),
    );
  }
}

class CatalogRow extends StatelessWidget {
  const CatalogRow({super.key, required this.entry});

  final StoreCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: const Icon(Icons.shopping_bag, color: Colors.green),
        ),
        title: Text(entry.product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(entry.product.unit.isEmpty ? entry.product.itemCategory : entry.product.unit),
        trailing: Text(
          "RM${entry.price.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
        onTap: () => context.push('/product/${entry.product.itemCode}'),
      ),
    );
  }
}

/// Price Comparison: products at this store where a cheaper price exists at
/// another store, biggest saving first.
class _PriceSavingsSection extends ConsumerWidget {
  const _PriceSavingsSection({required this.premiseCode});

  final String premiseCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(storeSavingsProvider(premiseCode));

    return savingsAsync.when(
      data: (savings) {
        if (savings.isEmpty) {
          return SupermarketDetailScreen._infoCard(
            icon: Icons.emoji_events,
            title: ref.tr('best_prices_found_title'),
            subtitle: ref.tr('best_prices_found_desc'),
          );
        }

        final shown = savings.take(_maxSavingsItems).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final saving in shown) ...[
              Card(
                elevation: 1,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF3E0),
                    child: Icon(Icons.trending_down, color: Colors.orange),
                  ),
                  title: Text(saving.entry.product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    ref.tr('price_here_vs_elsewhere')
                        .replaceAll('{here}', saving.entry.price.toStringAsFixed(2))
                        .replaceAll('{elsewhere}', saving.cheaperPrice.toStringAsFixed(2)),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/compare/${saving.entry.product.itemCode}'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => SupermarketDetailScreen._infoCard(
        icon: Icons.compare_arrows,
        title: ref.tr('could_not_load_comparison'),
        subtitle: ref.tr('check_connection_retry'),
      ),
    );
  }
}
