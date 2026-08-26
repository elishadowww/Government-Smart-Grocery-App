import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';

class SearchBarWidget extends ConsumerWidget {
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
  Widget build(BuildContext context,WidgetRef ref) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: ref.tr('search_supermarket_hint'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,

                isDense: true,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 52,
            height: 52,
            child: Material(
              color: Colors.white,
              elevation: 2,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onFilterPressed,
                child: const Icon(Icons.tune),
              ),
            ),
          ),
        ],
      ),
    );
  }
}