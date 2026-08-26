import 'package:flutter/material.dart';
import '../models/supermarket_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';

class SupermarketBottomSheet extends ConsumerWidget {
  final SupermarketModel supermarket;
  final VoidCallback onNavigate;
  final VoidCallback onViewPrices;

  const SupermarketBottomSheet({
    super.key,
    required this.supermarket,
    required this.onNavigate,
    required this.onViewPrices,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.green,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        supermarket.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 18,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            supermarket.rating
                                .toStringAsFixed(1),
                          ),

                          const SizedBox(width: 12),

                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: supermarket.isOpen
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius:
                              BorderRadius.circular(50),
                            ),
                            child: Text(
                              supermarket.isOpen
                                  ? ref.tr('open')
                                  : ref.tr('closed'),
                              style: TextStyle(
                                color: supermarket.isOpen
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
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
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation),
                    label: Text(ref.tr('navigate')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      side: const BorderSide(
                        color: Colors.green,
                      ),
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onViewPrices,
                    icon: const Icon(Icons.local_offer),
                    label: Text(ref.tr('view_prices')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
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