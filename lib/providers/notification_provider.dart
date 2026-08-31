import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import 'current_user_provider.dart';
import 'price_provider.dart';
import 'product_provider.dart';
import 'saved_product_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Runs the saved-product price scan once per signed-in session (and again
/// whenever the signed-in user changes), so a price change surfaces the
/// first time anything reads notification state — not only after the user
/// has opened the Notification Center screen.
final priceAlertScanProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return;
  await ref.read(notificationsControllerProvider).scanSavedProductsForPriceChanges();
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const [];
  await ref.watch(priceAlertScanProvider.future);
  return ref.watch(notificationRepositoryProvider).getAll(uid);
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return 0;
  await ref.watch(priceAlertScanProvider.future);
  return ref.watch(notificationRepositoryProvider).unreadCount(uid);
});

class NotificationsController {
  NotificationsController(this._ref);

  final Ref _ref;

  Future<void> markAllRead() async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    await _ref.read(notificationRepositoryProvider).markAllRead(uid);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> clearAll() async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    await _ref.read(notificationRepositoryProvider).clearAll(uid);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }

  /// Compares each saved product's current cheapest price against the price
  /// it was saved/last-notified at, and raises a notification for anything
  /// that changed (spec §7.9: "Saving a product automatically enables price
  /// tracking"). A product's tracked price is updated after each check, so
  /// an unchanged price never re-notifies.
  Future<void> scanSavedProductsForPriceChanges() async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;

    final savedRepo = _ref.read(savedProductRepositoryProvider);
    final tracked = await savedRepo.getTrackedPrices(uid);
    if (tracked.isEmpty) return;

    final priceRepo = _ref.read(priceRepositoryProvider);
    final productRepo = _ref.read(productRepositoryProvider);
    final notifRepo = _ref.read(notificationRepositoryProvider);

    var changed = false;

    for (final entry in tracked.entries) {
      final itemCode = entry.key;
      final previousPrice = entry.value;

      final prices = await priceRepo.getLatestPricesForItem(itemCode);
      if (prices.isEmpty) continue;
      final currentPrice = prices.first.price;

      if (previousPrice == null || currentPrice == previousPrice) {
        if (previousPrice == null) {
          await savedRepo.updateTrackedPrice(uid, itemCode, currentPrice);
        }
        continue;
      }

      final product = await productRepo.getById(itemCode);
      final name = product?.name ?? itemCode;
      final delta = currentPrice - previousPrice;
      final direction = delta < 0 ? 'dropped' : 'increased';
      final amount = delta.abs().toStringAsFixed(2);

      await notifRepo.add(
        uid,
        title: name,
        message:
            'Price $direction by RM$amount (now RM${currentPrice.toStringAsFixed(2)})',
      );
      await savedRepo.updateTrackedPrice(uid, itemCode, currentPrice);
      changed = true;
    }

    if (changed) {
      _ref.invalidate(notificationsProvider);
      _ref.invalidate(unreadNotificationCountProvider);
    }
  }

  // Mock Test For Notification Trigger
  Future<void> simulatePriceChangeForTesting({bool isDrop = true}) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;

    final notifRepo = _ref.read(notificationRepositoryProvider);
    final title = isDrop ? 'Cooking Oil price dropped' : 'Rice price increased';
    final amount = isDrop ? 'RM2.00' : 'RM1.00';

    await notifRepo.add(
      uid,
      title: title,
      message: amount,
    );

    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }
}

final notificationsControllerProvider = Provider<NotificationsController>((ref) {
  return NotificationsController(ref);
});
