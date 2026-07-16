import 'package:url_launcher/url_launcher.dart';

class RouteButton {
  static Future<void> navigate({
    required double latitude,
    required double longitude,
  }) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not open Google Maps.');
    }
  }
}