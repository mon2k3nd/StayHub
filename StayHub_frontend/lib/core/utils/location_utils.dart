import 'dart:math' as math;

class LocationUtils {
  /// Calculates the Haversine distance in kilometers between two coordinates.
  static double calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0; // Earth radius in km

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    final double straightLineDistance = earthRadiusKm * c;

    // Apply a tortuosity factor (hệ số ngoằn ngoèo) to approximate actual driving/walking distance
    // In urban areas like Hanoi/HCMC, road distance is typically 1.3 to 1.4 times the straight-line distance.
    const double routingMultiplier = 1.35;

    return straightLineDistance * routingMultiplier;
  }

  /// Alias for backward compatibility
  static double calculateDistanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return calculateHaversineDistance(lat1, lon1, lat2, lon2);
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
