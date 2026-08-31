import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../authentication/repositories/auth_repositories.dart';
import '../../../core/localization/app_strings.dart';

/// Navigation drawer (spec Fig 7.1.2).
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final identity = user == null || user.isAnonymous ? ref.tr('guest'): (user.email ?? ref.tr('registered_user'));

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.tr('app_name'),
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(identity, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: ref.tr('dashboard'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/dashboard');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.search,
                    label: ref.tr('search_products_menu'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/search');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.shopping_cart_outlined,
                    label: ref.tr('cart'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/cart');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.storefront_outlined,
                    label: ref.tr('nearby_supermarkets'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/nearby');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.trending_up,
                    label: ref.tr('price_trends'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/price_trends');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: ref.tr('my_budget'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/budget');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.favorite_border,
                    label: ref.tr('favourites'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/favourites');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: ref.tr('profile'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/profile');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: ref.tr('settings'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/settings');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    label: ref.tr('about'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/about');
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout,
              label: ref.tr('logout'),
              color: AppColors.error,
              onTap: () async {
                Navigator.of(context).pop();
                await AuthRepository().logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.text),
      title: Text(label, style: TextStyle(color: color ?? AppColors.text)),
      onTap: onTap,
    );
  }
}
