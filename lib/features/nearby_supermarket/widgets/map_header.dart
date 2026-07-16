import 'package:flutter/material.dart';
import 'category_chip.dart';
import 'search_bar.dart';

class MapHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SearchBarWidget(
              controller: searchController,
              onChanged: onSearchChanged,
              onFilterPressed: onFilterPressed,
            ),

            const SizedBox(height: 14),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryChip(
                    label: "All",
                    icon: Icons.apps,
                    isSelected: selectedCategory == "All",
                    onTap: () => onCategoryChanged("All"),
                  ),

                  CategoryChip(
                    label: "Grocery",
                    icon: Icons.shopping_basket,
                    isSelected: selectedCategory == "Grocery",
                    onTap: () => onCategoryChanged("Grocery"),
                  ),

                  CategoryChip(
                    label: "Hypermarket",
                    icon: Icons.store,
                    isSelected:
                    selectedCategory == "Hypermarket",
                    onTap: () =>
                        onCategoryChanged("Hypermarket"),
                  ),

                  CategoryChip(
                    label: "Convenience",
                    icon: Icons.local_convenience_store,
                    isSelected:
                    selectedCategory ==
                        "Convenience",
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