import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/services/geocoding_service.dart';
import '../core/services/location_service.dart';
import '../models/supermarket.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});

/// The device's current position, or null if location is unavailable
/// (permission denied, GPS off, etc.) — distance display degrades to "—"
/// rather than blocking price comparison, which doesn't depend on location.
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  try {
    return await ref.watch(locationServiceProvider).getCurrentLocation();
  } catch (_) {
    return null;
  }
});

/// Distance in km from the device to [supermarket], resolved by geocoding
/// its PriceCatcher address via Google Places (the dataset has no
/// coordinates). Null if either the device location or the store's
/// coordinates couldn't be resolved.
final storeDistanceKmProvider =
    FutureProvider.family<double?, Supermarket>((ref, supermarket) async {
  final position = await ref.watch(currentPositionProvider.future);
  if (position == null) return null;

  final point = await ref.watch(geocodingServiceProvider).resolve(
        cacheKey: supermarket.premiseCode,
        textQuery: '${supermarket.name}, ${supermarket.address}, '
            '${supermarket.district}, ${supermarket.state}, Malaysia',
      );
  if (point == null) return null;

  final meters = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    point.latitude,
    point.longitude,
  );
  return meters / 1000;
});
