import 'package:geolocator/geolocator.dart';

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationServiceException implements Exception {
  const LocationServiceException(
    this.message, {
    this.isPermanentDenied = false,
  });

  final String message;
  final bool isPermanentDenied;

  @override
  String toString() => message;
}

abstract class LocationService {
  Future<GeoPoint> getCurrentLocation();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<GeoPoint> getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationServiceException(
        'Location services are turned off. Please enable location access and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Location permission is required to find nearby hospitals.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permission is permanently denied. Enable it in system settings to find nearby hospitals.',
        isPermanentDenied: true,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return GeoPoint(latitude: position.latitude, longitude: position.longitude);
  }
}
