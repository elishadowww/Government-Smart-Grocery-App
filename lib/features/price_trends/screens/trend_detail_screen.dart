import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../providers/price_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/supermarket_provider.dart';
import '../widgets/history_table.dart';
import '../widgets/statistic_panel.dart';
import '../widgets/trend_chart.dart';

enum _TrendSort { date, price, alphabetical }

class TrendDetailScreen extends ConsumerStatefulWidget {
  final String itemCode;

  const TrendDetailScreen({super.key, required this.itemCode});

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  ConsumerState<TrendDetailScreen> createState() => _TrendDetailScreenState();
}

class _TrendDetailScreenState extends ConsumerState<TrendDetailScreen> {
  _TrendSort _sortBy = _TrendSort.date;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.itemCode));
    final historyAsync = ref.watch(priceHistoryProvider(PriceHistoryQuery(itemCode: widget.itemCode)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: TrendDetailScreen.primaryGreen),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Price Trends',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: productAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => InlineError(
          message: 'Could not load product details.',
          onRetry: () => ref.invalidate(productByIdProvider(widget.itemCode)),
        ),
        data: (product) {
          return historyAsync.when(
            loading: () => const AppLoading(),
            error: (err, _) => InlineError(
              message: 'Could not load price history.',
              onRetry: () => ref.invalidate(priceHistoryProvider(PriceHistoryQuery(itemCode: widget.itemCode))),
            ),
            data: (historyPrices) {
              final premiseCodesList = historyPrices
                  .map((p) => p.premiseCode.toString().trim())
                  .where((code) => code.isNotEmpty)
                  .toSet()
                  .toList()..sort();

              final premiseCodesKey = premiseCodesList.join(',');

              final storesAsync = ref.watch(supermarketByIdsKeyProvider(premiseCodesKey));

              return storesAsync.when(
                loading: () => const AppLoading(),
                error: (err, _) => InlineError(
                  message: 'Could not load store details.',
                  onRetry: () => ref.invalidate(supermarketByIdsKeyProvider(premiseCodesKey)),
                ),
                data: (stores) {
                  final storeByCode = {
                    for (final s in stores)
                      s.premiseCode.toString().trim(): s.name
                  };

                  final historyMaps = historyPrices.map((p) {
                    final premiseKey = p.premiseCode.toString().trim();
                    final storeName = storeByCode[premiseKey] ?? 'Supermarket';

                    return {
                      'date': p.date,
                      'name': storeName,
                      'store_name': storeName,
                      'price': p.price,
                    };
                  }).toList();

                  double lowest = 0.0;
                  double high = 0.0;
                  double avg = 0.0;

                  if (historyPrices.isNotEmpty) {
                    final prices = historyPrices.map((e) => e.price).toList();
                    lowest = prices.reduce((a, b) => a < b ? a : b);
                    high = prices.reduce((a, b) => a > b ? a : b);
                    avg = prices.reduce((a, b) => a + b) / prices.length;
                  }

                  final productName = product?.name ?? 'Item Code: ${widget.itemCode}';

                  // Sort history records specifically for HistoryTable presentation
                  final sortedHistoryMaps = List<Map<String, dynamic>>.from(historyMaps);
                  switch (_sortBy) {
                    case _TrendSort.date:
                      sortedHistoryMaps.sort((a, b) {
                        final dateA = DateTime.tryParse(a['date'].toString()) ?? DateTime(1970);
                        final dateB = DateTime.tryParse(b['date'].toString()) ?? DateTime(1970);
                        return dateB.compareTo(dateA); // Newest first
                      });
                      break;
                    case _TrendSort.price:
                      sortedHistoryMaps.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
                      break;
                    case _TrendSort.alphabetical:
                      sortedHistoryMaps.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
                      break;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        _buildSearchBar(context),
                        const SizedBox(height: 16),
                        _buildProductCard(productName, product?.itemCategory),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Column(
                            children: [
                              TrendChart(records: historyMaps),
                              const SizedBox(height: 16),
                              StatisticPanel(lowest: lowest, avg: avg, high: high),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Sort:', style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            DropdownButton<_TrendSort>(
                              value: _sortBy,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: _TrendSort.date, child: Text('Date')),
                                DropdownMenuItem(value: _TrendSort.price, child: Text('Price')),
                                DropdownMenuItem(
                                  value: _TrendSort.alphabetical,
                                  child: Text('Alphabetical'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _sortBy = value);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        HistoryTable(records: sortedHistoryMaps),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        readOnly: true,
        onTap: () => context.pop(),
        decoration: const InputDecoration(
          hintText: 'Search a product...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildProductCard(String title, String? category) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_grocery_store, color: Color(0xFFFFA000), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}