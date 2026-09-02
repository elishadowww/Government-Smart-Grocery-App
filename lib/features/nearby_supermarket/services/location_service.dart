import 'package:geolocator/geolocator.dart';

enum LocationErrorType { serviceDisabled, permissionDenied, permissionDeniedForever }

/// Thrown by [LocationService.getCurrentLocation]. Carries a [type] rather
/// than a hardcoded message so callers can present a localized string.
class LocationServiceException implements Exception {
  LocationServiceException(this.type);

  final LocationErrorType type;
}

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw LocationServiceException(LocationErrorType.serviceDisabled);
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationServiceException(LocationErrorType.permissionDenied);
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(LocationErrorType.permissionDeniedForever);
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}