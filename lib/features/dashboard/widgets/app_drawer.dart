import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../authentication/repositories/auth_repositories.dart';

/// Navigation drawer (spec Fig 7.1.2). Only screens that exist in this
/// build (Dashboard, Search, Cart, Nearby, Favourites) navigate for real;
/// modules outside this branch's scope (Price Trends, Profile, Settings,
/// About) show a placeholder instead of a dead route.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final identity = user == null || user.isAnonymous ? 'Guest' : (user.email ?? 'Registered User');

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
                  const Text(
                    'Smart Grocery',
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
                    label: 'Dashboard',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/dashboard');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.search,
                    label: 'Search Products',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/search');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Cart',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/cart');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.storefront_outlined,
                    label: 'Nearby Supermarkets',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/nearby');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.trending_up,
                    label: 'Price Trends',
                    onTap: () => _comingSoon(context),
                  ),
                  _DrawerItem(
                    icon: Icons.favorite_border,
                    label: 'Favourites',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/favourites');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () => _comingSoon(context),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => _comingSoon(context),
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    label: 'About',
                    onTap: () => _comingSoon(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Logout',
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

  void _comingSoon(BuildContext context) {
    Navigator.of(context).pop();
    showAppSnackBar(context, 'Coming soon');
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
