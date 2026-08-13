import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Button variants per Specifications.pdf §2.5: Filled (primary), Outlined
/// (secondary), Text (minor/tertiary).
enum AppButtonType { filled, outlined, text }

/// Wraps the app's themed Elevated/Outlined/Text buttons (see
/// app/theme/app_theme.dart) with an optional leading icon and loading
/// spinner, so call sites don't repeat that boilerplate.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.filled,
    this.icon,
    this.expand = true,
    this.loading = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool expand;
  final bool loading;

  /// Compact pill sizing for inline card actions (e.g. product card
  /// "Compare Prices" / "+ Add"), instead of the full-width 52dp buttons
  /// used for primary screen actions.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: type == AppButtonType.filled ? Colors.white : AppColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            ],
          );

    final Widget button = switch (type) {
      AppButtonType.filled => ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: dense
              ? ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                )
              : null,
          child: child,
        ),
      AppButtonType.outlined => OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: dense
              ? OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                )
              : null,
          child: child,
        ),
      AppButtonType.text => TextButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
    };

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
