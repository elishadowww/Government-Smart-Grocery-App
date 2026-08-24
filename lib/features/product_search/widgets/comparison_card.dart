import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/supermarket.dart';
import '../../../core/localization/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One store's row on the price comparison screen (spec Fig 7.3.3): name,
/// price, distance (real, geocoded — see providers/store_distance_provider),
/// and a "Cheapest" tag on the lowest-priced store.
class ComparisonRow extends ConsumerWidget {
  const ComparisonRow({
    super.key,
    required this.supermarket,
    required this.price,
    required this.isCheapest,
    required this.distanceKm,
    this.distanceLoading = false,
    this.onTap,
  });

  final Supermarket supermarket;
  final double price;
  final bool isCheapest;
  final double? distanceKm;
  final bool distanceLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            supermarket.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        if (isCheapest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ref.tr('cheapest'),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _distanceLabel(ref),
                      style: const TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _distanceLabel(WidgetRef ref) {
    if (distanceLoading) return ref.tr('locating');
    if (distanceKm == null) return supermarket.address;
    return '${distanceKm!.toStringAsFixed(1)} km';
  }
}
