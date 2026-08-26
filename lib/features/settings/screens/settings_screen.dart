import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'ms': 'Bahasa Melayu',
    'zh': '中文 (Chinese)',
  };

  void _showLanguagePicker(
      BuildContext context,
      WidgetRef ref,
      Locale currentLocale,
      ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ref.tr('select_language'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...supportedLanguages.entries.map((entry) {
                  final isSelected = currentLocale.languageCode == entry.key;
                  return ListTile(
                    title: Text(entry.value),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(entry.key);
                      context.pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final currentLanguageName =
        supportedLanguages[currentLocale.languageCode] ?? 'English';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(ref.tr('settings')),
      ),
      body: ListView(
        children: [
           Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              ref.tr('preferences'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.grey,
                fontSize: 12,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined, color: AppColors.primary),
            title: Text(ref.tr('language')),
            subtitle: Text(currentLanguageName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref, currentLocale),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}