import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// Emits true while the device has an active network connection, false
/// when offline. Backs the global "No Internet" screen (PRD §5 — "Offline:
/// Dedicated 'No Internet' screen").
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = ref.watch(connectivityProvider);
  yield _isOnline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_isOnline);
});

bool _isOnline(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}
