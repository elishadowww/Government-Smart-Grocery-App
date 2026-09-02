import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/locale_provider.dart';
import '../localization/app_strings.dart';
import 'app_button.dart';

String _tr(BuildContext context, String key) {
  final languageCode = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(localeProvider).languageCode;
  return AppStrings.tr(key, languageCode);
}

/// Guest-gating dialog (spec Fig 7.2.2), triggered when a Guest attempts a
/// registered-only action like "Save Product". Returns true if the user
/// tapped Login (and was navigated there), false/null on Cancel.
Future<bool?> showLoginRequiredDialog(
  BuildContext context, {
  String? message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_tr(context, 'login_required')),
      content: Text(message ?? _tr(context, 'login_required_message')),
      actions: [
        AppButton(
          label: _tr(context, 'cancel'),
          type: AppButtonType.text,
          expand: false,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: _tr(context, 'login'),
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
  String? confirmLabel,
  String? cancelLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton(
          label: cancelLabel ?? _tr(context, 'cancel'),
          type: AppButtonType.text,
          expand: false,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: confirmLabel ?? _tr(context, 'clear_all'),
          type: AppButtonType.filled,
          dense: true,
          expand: false,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
}
