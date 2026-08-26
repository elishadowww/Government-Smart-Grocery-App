import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/localization/legal_strings.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
            ref.tr('privacy_policy')
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: SelectableText(
            LegalStrings.privacyPolicy,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}