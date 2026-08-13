import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/supermarket.dart';
import '../repositories/supermarket_repository.dart';

final supermarketRepositoryProvider = Provider<SupermarketRepository>((ref) {
  return SupermarketRepository();
});

final supermarketByIdProvider =
    FutureProvider.family<Supermarket?, String>((ref, premiseCode) {
  return ref.watch(supermarketRepositoryProvider).getById(premiseCode);
});

final supermarketsByStateProvider =
    FutureProvider.family<List<Supermarket>, String>((ref, state) {
  return ref.watch(supermarketRepositoryProvider).getByState(state);
});

final supermarketsByDistrictProvider =
    FutureProvider.family<List<Supermarket>, String>((ref, district) {
  return ref.watch(supermarketRepositoryProvider).getByDistrict(district);
});

/// Batch lookup by premise code — used wherever a screen already has a set
/// of premise codes (e.g. cheapest-store lookups) and just needs names.
final supermarketByIdsProvider =
    FutureProvider.family<List<Supermarket>, List<String>>((ref, premiseCodes) {
  return ref.watch(supermarketRepositoryProvider).getByIds(premiseCodes);
});
