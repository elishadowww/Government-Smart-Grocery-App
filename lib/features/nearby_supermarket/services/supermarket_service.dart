import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/supermarket_model.dart';
import 'package:geolocator/geolocator.dart';

class SupermarketService {
  static const String _baseUrl =
      "https://places.googleapis.com/v1/places:searchNearby";

  Future<List<SupermarketModel>> getNearbySupermarkets({
    required double latitude,
    required double longitude,
  }) async {
    final apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Google Maps API Key not found.");
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask":
        "places.name,"
        "places.id,"
            "places.displayName,"
            "places.formattedAddress,"
            "places.location,"
            "places.rating,"
            "places.currentOpeningHours.openNow",
      },
      body: jsonEncode({
        "includedTypes": [
          "supermarket",
        ],
        "maxResultCount": 20,
        "locationRestriction": {
          "circle": {
            "center": {
              "latitude": latitude,
              "longitude": longitude,
            },
            "radius": 5000.0,
          }
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load nearby supermarkets.\n"
            "Status Code: ${response.statusCode}\n"
            "${response.body}",
      );
    }

    final Map<String, dynamic> json =
    jsonDecode(response.body);

    final List places = json["places"] ?? [];

    final supermarkets = places.map((place) {
      final supermarket =
      SupermarketModel.fromJson(place);

      final distanceInMeters =
      Geolocator.distanceBetween(
        latitude,
        longitude,
        supermarket.latitude,
        supermarket.longitude,
      );

      return SupermarketModel(
        id: supermarket.id,
        placeResourceName:
        supermarket.placeResourceName,
        name: supermarket.name,
        address: supermarket.address,
        latitude: supermarket.latitude,
        longitude: supermarket.longitude,
        rating: supermarket.rating,
        isOpen: supermarket.isOpen,
        distance: distanceInMeters / 1000,
      );
    }).toList();

    supermarkets.sort(
          (a, b) => a.distance.compareTo(b.distance),
    );

    return supermarkets;
  }
}