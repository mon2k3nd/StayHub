import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationService {
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // update every 50 meters
      ),
    );
  }

  Future<Position> getAccuratePosition() async {
    try {
      final stream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      // Đợi đến khi có tín hiệu GPS với độ sai số (accuracy) < 40 mét, hoặc timeout sau 6 giây
      return await stream
          .firstWhere((pos) => pos.accuracy < 40)
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () => Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.best,
              ),
            ),
          );
    } catch (e) {
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// Realtime location stream provider changed to FutureProvider to prevent Emulator crash
final realtimeLocationProvider = FutureProvider<Position>((ref) async {
  final service = ref.watch(locationServiceProvider);
  final hasPermission = await service.handleLocationPermission();

  if (hasPermission) {
    Position? position;
    try {
      position = await service.getAccuratePosition();
    } catch (e) {
      // Fallback
      position = await Geolocator.getLastKnownPosition();
    }
    if (position == null) {
      throw Exception('Cannot get location');
    }
    return position;
  } else {
    throw Exception('Location permission not granted');
  }
});
