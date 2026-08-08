import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'app_button.dart';

/// Inline error state for list-driven screens (spec §5: "Inline message
/// with a Retry button"), as opposed to [AppError] which takes over the
/// whole screen.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.text)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppButton(
                label: 'Retry',
                type: AppButtonType.outlined,
                expand: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
