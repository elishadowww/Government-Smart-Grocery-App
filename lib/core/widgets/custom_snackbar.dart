import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Transient confirmation feedback (spec §5: SnackBar pattern, e.g.
/// "Added to shopping list"). [actionLabel]/[onAction] add an inline action
/// (e.g. "View") for jumping straight to the thing that just changed.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.text,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.primary,
                onPressed: onAction,
              )
            : null,
      ),
    );
}
