import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onFilterPressed;
  final ValueChanged<String>? onChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onFilterPressed,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: "Search supermarket...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                blurRadius: 6,
                color: Colors.black12,
              ),
            ],
          ),
          child: IconButton(
            onPressed: onFilterPressed,
            icon: const Icon(
              Icons.tune,
            ),
          ),
        ),
      ],
    );
  }
}