import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';

/// "Recent Searches" chip row with a Clear All action (spec Fig 7.3.1).
class RecentSearches extends ConsumerWidget {
  const RecentSearches({
    super.key,
    required this.terms,
    required this.onSelect,
    required this.onClearAll,
  });

  final List<String> terms;
  final ValueChanged<String> onSelect;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (terms.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(
              ref.tr('recent_searches'),
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            GestureDetector(
              onTap: onClearAll,
              child: Text(
                ref.tr('clear_all'),
                style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final term in terms)
              ActionChip(
                label: Text(term),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none,
                ),
                labelStyle: const TextStyle(color: AppColors.primary, fontSize: 13),
                onPressed: () => onSelect(term),
              ),
          ],
        ),
      ],
    );
  }
}
