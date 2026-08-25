import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/localization/app_strings.dart';

class LocationErrorCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
                      ? ref.tr('location_required')
                      : ref.tr('could_not_load_supermarkets'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _isGpsDisabled
                      ? ref.tr('location_service_disabled_msg')
                      : _isPermissionDenied
                          ? ref.tr('location_permission_denied_msg')
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
                          ? ref.tr('turn_on_location')
                          : _isPermissionDenied
                              ? ref.tr('grant_permission')
                              : ref.tr('retry'),
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