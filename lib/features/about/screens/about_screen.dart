import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';

/// About screen (drawer "About" item lands here).
/// Shows the app identity, version, and links to the legal screens that
/// already exist (Terms of Service, Privacy Policy).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(ref.tr('about')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Image.asset('assets/images/logo.png', width: 64, height: 64),
                const SizedBox(height: 12),
                Text(
                  ref.tr('app_name'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  ref.tr('shopping_assistant'),
                  style: const TextStyle(color: AppColors.grey),
                ),
                const SizedBox(height: 12),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final versionText = info == null
                        ? ''
                        : '${ref.tr('app_version')} ${info.version} (${info.buildNumber})';
                    return Text(
                      versionText,
                      style: const TextStyle(color: AppColors.grey, fontSize: 12),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              ref.tr('legal'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.grey,
                fontSize: 12,
              ),
            ),
          ),
          _AboutMenuTile(
            icon: Icons.description_outlined,
            label: ref.tr('terms_of_service'),
            onTap: () => context.push('/terms'),
          ),
          _AboutMenuTile(
            icon: Icons.privacy_tip_outlined,
            label: ref.tr('privacy_policy'),
            onTap: () => context.push('/privacy'),
          ),
        ],
      ),
    );
  }
}

class _AboutMenuTile extends StatelessWidget {
  const _AboutMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
