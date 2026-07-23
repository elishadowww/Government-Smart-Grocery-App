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
