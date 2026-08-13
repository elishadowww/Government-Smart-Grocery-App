import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_button.dart';

/// Guest-gating dialog (spec Fig 7.2.2), triggered when a Guest attempts a
/// registered-only action like "Save Product". Returns true if the user
/// tapped Login (and was navigated there), false/null on Cancel.
Future<bool?> showLoginRequiredDialog(
  BuildContext context, {
  String message = 'Please log in to save favourites and receive price alerts.',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Login Required'),
      content: Text(message),
      actions: [
        AppButton(
          label: 'Cancel',
          type: AppButtonType.text,
          expand: false,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: 'Login',
          type: AppButtonType.filled,
          dense: true,
          expand: false,
          onPressed: () {
            Navigator.of(context).pop(true);
            context.push('/login');
          },
        ),
      ],
    ),
  );
}

/// Generic destructive-action confirmation (spec §5: "Dialog for ...
/// destructive-action confirmation, e.g. Clear All").
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Clear All',
  String cancelLabel = 'Cancel',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton(
          label: cancelLabel,
          type: AppButtonType.text,
          expand: false,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: confirmLabel,
          type: AppButtonType.filled,
          dense: true,
          expand: false,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
}
