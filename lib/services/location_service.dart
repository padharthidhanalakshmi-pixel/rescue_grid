import 'package:geolocator/geolocator.dart';

import '../models/campus_location.dart';

class LocationResult {
  const LocationResult({this.reading, this.error});
  final GeoReading? reading;
  final String? error;
  bool get ok => reading != null;
}

/// Real device GPS through geolocator. Never substitutes fake coordinates
/// when real GPS is available; on failure it returns a readable error and the
/// UI lets the user continue with a campus location in DEMO MODE.
class LocationService {
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(error: 'Location services are turned off.');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        return const LocationResult(error: 'Location permission denied.');
      }
      if (perm == LocationPermission.deniedForever) {
        return const LocationResult(error: 'Location permission permanently denied. Enable it in system settings.');
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult(
        reading: GeoReading(latitude: p.latitude, longitude: p.longitude, accuracy: p.accuracy, isReal: true),
      );
    } catch (e) {
      return LocationResult(error: 'Location unavailable ($e).');
    }
  }
}
