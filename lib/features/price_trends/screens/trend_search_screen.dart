import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/recent_search_provider.dart';
import 'trend_detail_screen.dart';
import '../../../core/localization/app_strings.dart';

class TrendSearchScreen extends ConsumerStatefulWidget {
  const TrendSearchScreen({super.key});

  @override
  ConsumerState<TrendSearchScreen> createState() => _TrendSearchScreenState();
}

class _TrendSearchScreenState extends ConsumerState<TrendSearchScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _query = val;
        });
      }
    });
  }

  void _selectQuery(String selectedQuery) {
    _searchController.text = selectedQuery;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: selectedQuery.length),
    );
    setState(() {
      _query = selectedQuery;
    });
  }

  void _saveRecentSearch(String text) {
    final cleanText = text.trim();
    if (cleanText.isNotEmpty) {
      ref.read(recentSearchesControllerProvider).record(cleanText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isQueryEmpty = _query.trim().isEmpty;
    final productsAsync = isQueryEmpty ? null : ref.watch(productSearchProvider(_query));
    final recentSearchesAsync = ref.watch(recentSearchesProvider);

    // Safely extract data across all Riverpod versions
    final recentSearches = recentSearchesAsync.asData?.value ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen),
          onPressed: () => context.pop(),
        ),
        title: Text(
          ref.tr('price_trends'),
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            if (isQueryEmpty) ...[
              _buildRecentSearchesSection(recentSearches),
            ] else ...[
              Text(
                ref.tr('search_results'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: productsAsync!.when(
                  loading: () => const AppLoading(),
                  error: (err, _) => InlineError(
                    message: ref.tr('could_not_load_products'),
                    onRetry: () => ref.invalidate(productSearchProvider(_query)),
                  ),
                  data: (products) {
                    if (products.isEmpty) {
                      return Center(
                        child: Text(
                          ref.tr('no_products_found'),
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.local_grocery_store,
                              color: Color(0xFFFFA000),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF333333),
                            ),
                          ),
                          subtitle: Text(
                            '${product.itemCategory} • ${product.unit}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: primaryGreen,
                          ),
                          onTap: () {
                            _saveRecentSearch(_query.isEmpty ? product.name : _query);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrendDetailScreen(
                                  itemCode: product.itemCode,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onSubmitted: (val) => _saveRecentSearch(val),
        style: const TextStyle(color: Color(0xFF333333)),
        decoration: InputDecoration(
          hintText: ref.tr('search_product_hint'),
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _query = '';
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRecentSearchesSection(List<String> recentSearches) {
    if (recentSearches.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                ref.tr('search_trend_instruction'),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ref.tr('recent_searches'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(recentSearchesControllerProvider).clearAll();
              },
              child: Text(
                ref.tr('clear_all'),
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: recentSearches.map((term) {
            return ActionChip(
              label: Text(
                term,
                style: const TextStyle(color: Color(0xFF333333), fontSize: 13),
              ),
              backgroundColor: const Color(0xFFF5F5F5),
              onPressed: () => _selectQuery(term),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}