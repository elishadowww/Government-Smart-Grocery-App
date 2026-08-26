import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';

class HistoryTable extends ConsumerWidget {
  final List<Map<String, dynamic>> records;

  const HistoryTable({super.key, required this.records});

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Center(
          child: Text(
            ref.tr('no_price_history_available'),
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F7F3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: primaryGreen),
                      SizedBox(width: 6),
                      Text(
                        ref.tr('date'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 16, color: primaryGreen),
                      SizedBox(width: 6),
                      Text(
                        ref.tr('store'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.sell_outlined, size: 16, color: primaryGreen),
                      SizedBox(width: 6),
                      Text(
                        ref.tr('price'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),

          // Log List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (context, index) {
              final item = records[index];
              final String rawDate = item['date']?.toString() ?? '—';
              final String date = rawDate.split(' ').first;
              final String store = item['store_name']?.toString() ?? ref.tr('supermarket');
              final double price = (item['price'] as num?)?.toDouble() ?? 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        date,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        store,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'RM${price.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}