import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/recent_search_repository.dart';
import 'current_user_provider.dart';

final recentSearchRepositoryProvider = Provider<RecentSearchRepository>((ref) {
  return RecentSearchRepository();
});

final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const [];
  return ref.watch(recentSearchRepositoryProvider).getRecent(uid);
});

class RecentSearchesController {
  RecentSearchesController(this._ref);

  final Ref _ref;

  Future<void> record(String term) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null || term.trim().isEmpty) return;
    await _ref.read(recentSearchRepositoryProvider).add(uid, term);
    _ref.invalidate(recentSearchesProvider);
  }

  Future<void> clearAll() async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    await _ref.read(recentSearchRepositoryProvider).clearAll(uid);
    _ref.invalidate(recentSearchesProvider);
  }
}

final recentSearchesControllerProvider = Provider<RecentSearchesController>((ref) {
  return RecentSearchesController(ref);
});
