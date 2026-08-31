import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';
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

  @override
  ConsumerState<TrendDetailScreen> createState() => _TrendDetailScreenState();
}

class _TrendDetailScreenState extends ConsumerState<TrendDetailScreen> {
  _TrendSort _sortBy = _TrendSort.date;
  bool _ascending = false;
  String? _selectedMonth;

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatMonth(String ym) {
    final year = ym.substring(0, 4);
    final month = int.parse(ym.substring(5, 7));
    return '${_monthNames[month - 1]} $year';
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.itemCode));
    final monthsAsync = ref.watch(priceHistoryMonthsProvider(widget.itemCode));
    final historyAsync = ref.watch(priceHistoryProvider(
      PriceHistoryQuery(itemCode: widget.itemCode, month: _selectedMonth),
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          tooltip: ref.tr('back'),
          onPressed: () => context.pop(),
        ),
        title: Text(
          ref.tr('price_trends'),
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: productAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => InlineError(
          message: ref.tr('could_not_load_product_details'),
          onRetry: () => ref.invalidate(productByIdProvider(widget.itemCode)),
        ),
        data: (product) {
          return historyAsync.when(
            loading: () => const AppLoading(),
            error: (err, _) => InlineError(
              message: ref.tr('could_not_load_price_history'),
              onRetry: () => ref.invalidate(priceHistoryProvider(
                PriceHistoryQuery(itemCode: widget.itemCode, month: _selectedMonth),
              )),
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
                  message: ref.tr('could_not_load_store_details'),
                  onRetry: () => ref.invalidate(supermarketByIdsKeyProvider(premiseCodesKey)),
                ),
                data: (stores) {
                  final storeByCode = {
                    for (final s in stores)
                      s.premiseCode.toString().trim(): s.name
                  };

                  final historyMaps = historyPrices.map((p) {
                    final premiseKey = p.premiseCode.toString().trim();
                    final storeName = storeByCode[premiseKey] ?? ref.tr('supermarket');

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

                  final validPrices = historyPrices
                      .map((e) => e.price)
                      .where((p) => p > 0)
                      .toList();
                  final hasStats = validPrices.isNotEmpty;

                  if (hasStats) {
                    lowest = validPrices.reduce((a, b) => a < b ? a : b);
                    high = validPrices.reduce((a, b) => a > b ? a : b);
                    avg = validPrices.reduce((a, b) => a + b) / validPrices.length;
                  }

                  final productName =
                      product?.name ?? '${ref.tr('item_code_label')}: ${widget.itemCode}';

                  // Sort history records specifically for HistoryTable presentation
                  final sortedHistoryMaps = List<Map<String, dynamic>>.from(historyMaps);
                  int compare(Map<String, dynamic> a, Map<String, dynamic> b) {
                    switch (_sortBy) {
                      case _TrendSort.date:
                        final dateA = DateTime.tryParse(a['date'].toString()) ?? DateTime(1970);
                        final dateB = DateTime.tryParse(b['date'].toString()) ?? DateTime(1970);
                        return dateA.compareTo(dateB);
                      case _TrendSort.price:
                        return (a['price'] as num).compareTo(b['price'] as num);
                      case _TrendSort.alphabetical:
                        return (a['name'] as String).compareTo(b['name'] as String);
                    }
                  }

                  sortedHistoryMaps.sort((a, b) => _ascending ? compare(a, b) : compare(b, a));

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
                              StatisticPanel(lowest: lowest, avg: avg, high: high, hasData: hasStats),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(ref.tr('month'), style: const TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            DropdownButton<String?>(
                              value: _selectedMonth,
                              underline: const SizedBox.shrink(),
                              items: [
                                DropdownMenuItem<String?>(value: null, child: Text(ref.tr('all'))),
                                ...(monthsAsync.value ?? const <String>[]).map(
                                  (ym) => DropdownMenuItem<String?>(
                                    value: ym,
                                    child: Text(_formatMonth(ym)),
                                  ),
                                ),
                              ],
                              onChanged: (value) => setState(() => _selectedMonth = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(ref.tr('sort'), style: const TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            DropdownButton<_TrendSort>(
                              value: _sortBy,
                              underline: const SizedBox.shrink(),
                              items: [
                                DropdownMenuItem(value: _TrendSort.date, child: Text(ref.tr('date'))),
                                DropdownMenuItem(value: _TrendSort.price, child: Text(ref.tr('price'))),
                                DropdownMenuItem(
                                  value: _TrendSort.alphabetical,
                                  child: Text(ref.tr('alphabetical')),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _sortBy = value);
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(
                                _ascending
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: AppColors.primary,
                              ),
                              tooltip: _ascending ? 'Ascending' : 'Descending',
                              onPressed: () => setState(() => _ascending = !_ascending),
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
        decoration: InputDecoration(
          hintText: ref.tr('search_a_product'),
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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