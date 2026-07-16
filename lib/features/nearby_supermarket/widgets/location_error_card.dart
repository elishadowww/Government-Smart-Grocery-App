import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const LocationErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  bool get _isGpsDisabled =>
      message.toLowerCase().contains("location services");

  bool get _isPermissionDenied =>
      message.toLowerCase().contains("permission");

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.location_off_rounded,
                  size: 70,
                  color: Colors.redAccent,
                ),

                const SizedBox(height: 18),

                const Text(
                  "Location Required",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _isGpsDisabled
                      ? "Please turn on your device's location service to discover nearby supermarkets."
                      : "Please allow location permission to discover nearby supermarkets.",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.location_on),
                    label: Text(
                      _isGpsDisabled
                          ? "Turn On Location"
                          : "Grant Permission",
                    ),
                    onPressed: () async {
                      if (_isGpsDisabled) {
                        await Geolocator.openLocationSettings();
                      } else if (_isPermissionDenied) {
                        await Geolocator.openAppSettings();
                      }

                      onRetry();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}