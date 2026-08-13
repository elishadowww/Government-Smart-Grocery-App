import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// A resolved geographic point for a store address.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Resolves a PriceCatcher supermarket's text address to coordinates via the
/// Google Places API (Text Search), so Module 1 can show a real "distance to
/// store" — the PriceCatcher dataset only has address/district/state text,
/// no coordinates.
///
/// Results are cached in memory for the life of the service instance (which
/// is a singleton via [geocodingServiceProvider]), since a store's location
/// never changes within a session and Places calls are billed per request.
class GeocodingService {
  GeocodingService();

  static const String _baseUrl = 'https://places.googleapis.com/v1/places:searchText';

  final Map<String, GeoPoint?> _cache = {};

  /// Returns null if the store couldn't be geocoded (no API key, no match,
  /// or a network failure) — callers should degrade gracefully (e.g. show
  /// "—" instead of a distance) rather than fail the whole screen.
  Future<GeoPoint?> resolve({
    required String cacheKey,
    required String textQuery,
  }) async {
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    final point = await _fetch(textQuery);
    _cache[cacheKey] = point;
    return point;
  }

  Future<GeoPoint?> _fetch(String textQuery) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': 'places.location',
        },
        body: jsonEncode({'textQuery': textQuery, 'maxResultCount': 1}),
      );

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final places = json['places'] as List?;
      if (places == null || places.isEmpty) return null;

      final location = places.first['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      final lat = (location['latitude'] as num?)?.toDouble();
      final lng = (location['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return GeoPoint(lat, lng);
    } catch (_) {
      return null;
    }
  }
}
