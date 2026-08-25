import 'package:equatable/equatable.dart';

import '../core/constants/user_data_constants.dart';

/// An in-app notification (currently: saved-product price-change alerts).
/// Backs the Notification Centre (spec §7.9). In-app only — no push.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
  });

  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;

  String get searchQuery {
    return title
        .replaceAll(RegExp(r'\s+price\s+(dropped|increased)$', caseSensitive: false), '')
        .trim();
  }

  bool get isDrop => title.toLowerCase().contains('dropped');

  factory AppNotification.fromMap(Map<String, Object?> row) {
    return AppNotification(
      id: row[NotificationColumns.id] as int,
      title: row[NotificationColumns.title] as String? ?? '',
      message: row[NotificationColumns.message] as String? ?? '',
      createdAt: DateTime.tryParse(
            row[NotificationColumns.createdAt] as String? ?? '',
          ) ??
          DateTime.now(),
      read: (row[NotificationColumns.read] as int? ?? 0) != 0,
    );
  }

  @override
  List<Object?> get props => [id, title, message, createdAt, read];
}
