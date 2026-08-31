import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../providers/price_provider.dart';
import 'supermarket_detail_screen.dart';

/// Full Product Catalogue for a single store — reached from the "View all"
/// link on [SupermarketDetailScreen] once the inline preview (capped at
/// `_maxCatalogItems`) isn't enough.
class StoreCatalogScreen extends ConsumerStatefulWidget {
  const StoreCatalogScreen({
    super.key,
    required this.premiseCode,
    required this.storeName,
    required this.isApproximateMatch,
  });

  final String premiseCode;
  final String storeName;
  final bool isApproximateMatch;

  @override
  ConsumerState<StoreCatalogScreen> createState() => _StoreCatalogScreenState();
}

class _StoreCatalogScreenState extends ConsumerState<StoreCatalogScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(storeCatalogProvider(widget.premiseCode));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ref.tr('store_product_catalogue'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            AppSearchBar(
              controller: _searchController,
              hintText: ref.tr('search_products'),
              onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 15),
            if (widget.isApproximateMatch)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  ref.tr('approximate_match_warning'),
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                ),
              ),
            Expanded(
              child: catalogAsync.when(
                data: (entries) {
                  final filtered = _query.isEmpty
                      ? entries
                      : entries
                          .where((entry) => entry.product.name.toLowerCase().contains(_query))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(child: Text(ref.tr('no_products_found')));
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => CatalogRow(entry: filtered[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(child: Text(ref.tr('could_not_load_products'))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
