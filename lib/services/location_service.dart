import 'package:geolocator/geolocator.dart';

class LocationService {
  Stream<Position> positionStream({
    required int distanceFilterMeters,
  }) {
    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<Position> currentHighAccuracy() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}

