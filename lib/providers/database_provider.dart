import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Resolves once the local SQLite database is open — copying it from
/// assets/database/pricecatcher.db on first launch if needed.
///
/// The app root watches this to gate rendering until the database is
/// ready, and to show a clear message if the asset hasn't been placed yet
/// (see [DatabaseNotAvailableException]).
final databaseInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(databaseServiceProvider);
  await service.database;
});

/// First-launch copy progress in [0.0, 1.0] — lets the loading screen show
/// real progress instead of a bare spinner while [databaseInitProvider] is
/// pending. Never emits once the database is already in place.
final databaseCopyProgressProvider = StreamProvider<double>((ref) {
  return ref.watch(databaseServiceProvider).copyProgress;
});
