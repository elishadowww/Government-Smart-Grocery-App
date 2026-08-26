import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import 'category_chip.dart';
import 'search_bar.dart';

class MapHeader extends ConsumerWidget {
  final TextEditingController searchController;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback? onFilterPressed;

  const MapHeader({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SearchBarWidget(
              controller: searchController,
              onChanged: onSearchChanged,
              onFilterPressed: onFilterPressed,
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  CategoryChip(
                    label: ref.tr('all'),
                    icon: Icons.apps,
                    isSelected: selectedCategory == "All",
                    onTap: () => onCategoryChanged("All"),
                  ),

                  CategoryChip(
                    label: ref.tr('grocery'),
                    icon: Icons.shopping_basket,
                    isSelected: selectedCategory == "Grocery",
                    onTap: () => onCategoryChanged("Grocery"),
                  ),

                  CategoryChip(
                    label: ref.tr('hypermarket'),
                    icon: Icons.store,
                    isSelected:
                    selectedCategory == "Hypermarket",
                    onTap: () =>
                        onCategoryChanged("Hypermarket"),
                  ),

                  CategoryChip(
                    label: ref.tr('convenience'),
                    icon: Icons.local_convenience_store,
                    isSelected:
                    selectedCategory == "Convenience",
                    onTap: () =>
                        onCategoryChanged("Convenience"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}