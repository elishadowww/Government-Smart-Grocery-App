import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// "Recent Searches" chip row with a Clear All action (spec Fig 7.3.1).
class RecentSearches extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (terms.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            GestureDetector(
              onTap: onClearAll,
              child: const Text(
                'Clear All',
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
