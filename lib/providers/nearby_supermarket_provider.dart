import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/nearby_supermarket/models/supermarket_model.dart';
import '../features/nearby_supermarket/services/supermarket_service.dart';
import '../models/supermarket.dart';
import 'price_provider.dart';
import 'recent_product_provider.dart';
import 'store_distance_provider.dart';
import 'supermarket_provider.dart';

final supermarketServiceProvider = Provider<SupermarketService>((ref) {
  return SupermarketService();
});

/// Supermarkets near the device's current position (Google Places, 5km
/// radius), nearest first. Empty if location is unavailable or the Places
/// lookup fails, so callers can degrade gracefully rather than error out.
final nearbyPlacesProvider = FutureProvider<List<SupermarketModel>>((ref) async {
  try {
    final position = await ref.watch(locationServiceProvider).getCurrentLocation();
    return await ref.watch(supermarketServiceProvider).getNearbySupermarkets(
          latitude: position.latitude,
          longitude: position.longitude,
        );
  } catch (_) {
    return const [];
  }
});

/// A nearby Places result matched to its PriceCatcher premise, with the
/// device-to-store distance Places already computed (so, unlike price
/// comparison's [storeDistanceKmProvider], this needs no per-item geocoding
/// — one location fix and one Places call cover every nearby candidate).
typedef NearbyCheapestStore = ({Supermarket premise, double distanceKm});

/// The nearest Places result, among the closest few, that is confidently
/// matched to a PriceCatcher premise and cheapest for the user's recent
/// products — backs the Dashboard's Nearby Cheapest Supermarket card (spec
/// Fig 7.1.1). Candidates are capped to the 8 nearest Places results so
/// matching stays bounded; ties on "cheapest" favour whichever is nearer
/// since candidates are already walked nearest-first.
final nearbyCheapestSupermarketProvider = FutureProvider<NearbyCheapestStore?>((ref) async {
  final places = await ref.watch(nearbyPlacesProvider.future);
  if (places.isEmpty) return null;

  final recentProducts = await ref.watch(recentProductsProvider.future);
  final itemCodes = recentProducts.map((p) => p.itemCode).toSet();

  final priceRepository = ref.watch(priceRepositoryProvider);
  NearbyCheapestStore? best;
  double? bestTotal;

  for (final place in places.take(8)) {
    final match = await ref.watch(matchedPremiseForPlaceProvider(place).future);
    if (match == null || match.isApproximate) continue;

    double total = 0;
    if (itemCodes.isNotEmpty) {
      final prices = await priceRepository.getLatestPricesForPremise(match.supermarket.premiseCode);
      final matched = prices.where((p) => itemCodes.contains(p.itemCode));
      if (matched.isEmpty) continue;
      total = matched.fold(0, (sum, p) => sum + p.price);
    }

    if (bestTotal == null || total < bestTotal) {
      bestTotal = total;
      best = (premise: match.supermarket, distanceKm: place.distance);
    }
  }

  return best;
});
