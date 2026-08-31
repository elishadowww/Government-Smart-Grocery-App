import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../providers/connectivity_provider.dart';
import '../localization/app_strings.dart';
import 'app_button.dart';

/// Dedicated full-screen "No Internet" state (PRD §5 Global UX & System
/// States — "Offline: Dedicated 'No Internet' screen"). Shown app-wide
/// whenever connectivity drops; Retry re-checks the connection immediately
/// instead of waiting for the next connectivity change event.
class NoInternetScreen extends ConsumerWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.grey),
                const SizedBox(height: 20),
                Text(
                  ref.tr('no_internet_title'),
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  ref.tr('no_internet_message'),
                  style: AppTextStyles.body.copyWith(color: AppColors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: ref.tr('retry'),
                  icon: Icons.refresh_rounded,
                  expand: false,
                  onPressed: () => ref.invalidate(isOnlineProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
