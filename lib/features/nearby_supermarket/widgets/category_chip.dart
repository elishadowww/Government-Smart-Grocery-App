import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.green,
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        showCheckmark: false,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 2,
        ),
      ),
    );
  }
}