class SupermarketModel {
  final String id;
  final String placeResourceName;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final bool isOpen;
  final double distance;

  const SupermarketModel({
    required this.id,
    required this.placeResourceName,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.isOpen,
    required this.distance,
  });

  factory SupermarketModel.fromJson(Map<String, dynamic> json) {
    final location = json["location"] ?? {};

    return SupermarketModel(

      id: json["id"] ?? "",

      placeResourceName: json["name"] ?? "",

      name: json["displayName"]?["text"] ?? "Unknown Supermarket",

      address: json["formattedAddress"] ?? "",

      latitude: (location["latitude"] ?? 0.0).toDouble(),

      longitude: (location["longitude"] ?? 0.0).toDouble(),

      rating: (json["rating"] ?? 0.0).toDouble(),

      isOpen: json["currentOpeningHours"]?["openNow"] ?? false,

      distance: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "placeResourceName": placeResourceName,
      "name": name,
      "address": address,
      "latitude": latitude,
      "longitude": longitude,
      "rating": rating,
      "isOpen": isOpen,
      "distance": distance,
    };
  }

  @override
  String toString() {
    return "SupermarketModel(name: $name, address: $address)";
  }
}