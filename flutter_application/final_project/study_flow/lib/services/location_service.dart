import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Resolves the device's current location into a human-readable place name.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  static const String unknown = 'Location Unknown';

  /// Returns a readable place name (e.g. "Jakarta, Indonesia") for the current
  /// position, or [unknown] if location services/permission are unavailable.
  Future<String> getCurrentLocationName() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return unknown;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return unknown;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if ((p.locality ?? '').isNotEmpty) p.locality!,
            if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea!,
            if ((p.country ?? '').isNotEmpty) p.country!,
          ];
          if (parts.isNotEmpty) return parts.join(', ');
        }
      } catch (_) {
        // Reverse geocoding failed — fall back to raw coordinates.
      }

      return '${position.latitude.toStringAsFixed(4)}, '
          '${position.longitude.toStringAsFixed(4)}';
    } catch (_) {
      return unknown;
    }
  }
}
