import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/cart_app_bar_action.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/search_query_provider.dart';
import '../../../core/localization/app_strings.dart';

/// Notification Centre (spec §7.9): in-app only, no push. Populated by
/// scanning saved products for price changes each time the screen opens.
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsControllerProvider).scanSavedProductsForPriceChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('notifications')),
        actions: [
          //Debug: Test buttons for notification
          if (kDebugMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.bug_report, color: Colors.amber),
              onSelected: (val) async {
                final controller = ref.read(notificationsControllerProvider);
                if (val == 'drop') {
                  await controller.simulatePriceChangeForTesting(isDrop: true);
                } else {
                  await controller.simulatePriceChangeForTesting(isDrop: false);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'drop', child: Text('Test: Price Drop')),
                PopupMenuItem(value: 'increase', child: Text('Test: Price Increase')),
              ],
            ),
          const CartAppBarAction(),
          TextButton(
            onPressed: () => ref.read(notificationsControllerProvider).markAllRead(),
            child: Text(ref.tr('mark_all')),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return AppEmptyState(
              icon: Icons.notifications_none,
              message: ref.tr('no_notifications_yet'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _NotificationTile(notifications[index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AppButton(
                  label: ref.tr('clear_all'),
                  type: AppButtonType.outlined,
                  icon: Icons.delete_outline,
                  onPressed: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: ref.tr('clear_all_notifications_title'),
                      message: ref.tr('clear_all_notifications_message'),
                    );
                    if (confirmed == true) {
                      await ref.read(notificationsControllerProvider).clearAll();
                    }
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const SkeletonListLoader(),
        error: (e, _) => InlineError(
          message: ref.tr('could_not_load_notifications'),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile(this.notification);

  final AppNotification notification;
  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        ref.read(activeSearchQueryProvider.notifier).setQuery(notification.searchQuery);

        context.push('/search');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.read ? AppColors.white : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE8F5E9),
              child: Icon(
                notification.isDrop ? Icons.arrow_downward : Icons.arrow_upward,
                color: primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _relativeTime(notification.createdAt, ref),
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            if (!notification.read)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime time, WidgetRef ref) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }
}
