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
      message.toLowerCase().contains("location services are disabled");

  bool get _isPermissionDenied =>
      message.toLowerCase().contains("location permission");

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

                Icon(
                  _isGpsDisabled || _isPermissionDenied
                      ? Icons.location_off_rounded
                      : Icons.error_outline_rounded,
                  size: 70,
                  color: Colors.redAccent,
                ),

                const SizedBox(height: 18),

                Text(
                  _isGpsDisabled || _isPermissionDenied
                      ? "Location Required"
                      : "Couldn't Load Supermarkets",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _isGpsDisabled
                      ? "Please turn on your device's location service to discover nearby supermarkets."
                      : _isPermissionDenied
                          ? "Please allow location permission to discover nearby supermarkets."
                          : message,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      _isGpsDisabled || _isPermissionDenied
                          ? Icons.location_on
                          : Icons.refresh,
                    ),
                    label: Text(
                      _isGpsDisabled
                          ? "Turn On Location"
                          : _isPermissionDenied
                              ? "Grant Permission"
                              : "Retry",
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