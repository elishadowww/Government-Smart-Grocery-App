import '../core/constants/user_data_constants.dart';
import '../core/services/user_data_service.dart';
import '../models/notification_model.dart';

/// Data access for the in-app Notification Centre (spec §7.9). In-app only
/// — no push notifications in this scope.
class NotificationRepository {
  NotificationRepository({UserDataService? service})
      : _service = service ?? UserDataService();

  final UserDataService _service;

  Future<void> add(String uid, {required String title, required String message}) async {
    final db = await _service.database;
    await db.insert(UserDataTables.notifications, {
      NotificationColumns.uid: uid,
      NotificationColumns.title: title,
      NotificationColumns.message: message,
      NotificationColumns.createdAt: DateTime.now().toIso8601String(),
      NotificationColumns.read: 0,
    });
  }

  Future<List<AppNotification>> getAll(String uid) async {
    final db = await _service.database;
    final rows = await db.query(
      UserDataTables.notifications,
      where: '${NotificationColumns.uid} = ?',
      whereArgs: [uid],
      orderBy: '${NotificationColumns.createdAt} DESC',
    );
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<int> unreadCount(String uid) async {
    final db = await _service.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${UserDataTables.notifications} '
      'WHERE ${NotificationColumns.uid} = ? AND ${NotificationColumns.read} = 0',
      [uid],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> markAllRead(String uid) async {
    final db = await _service.database;
    await db.update(
      UserDataTables.notifications,
      {NotificationColumns.read: 1},
      where: '${NotificationColumns.uid} = ?',
      whereArgs: [uid],
    );
  }

  Future<void> clearAll(String uid) async {
    final db = await _service.database;
    await db.delete(
      UserDataTables.notifications,
      where: '${NotificationColumns.uid} = ?',
      whereArgs: [uid],
    );
  }
}
