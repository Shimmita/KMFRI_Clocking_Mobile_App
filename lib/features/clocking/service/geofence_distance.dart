import 'dart:math';

class GeofenceDistance {
  static double metersBetween(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const earthRadiusMeters = 6371000.0;
    double radians(double degrees) => degrees * pi / 180;

    final latitudeDelta = radians(latitudeB - latitudeA);
    final longitudeDelta = radians(longitudeB - longitudeA);


    final haversine =
        (pow(sin(latitudeDelta / 2), 2) +
                cos(radians(latitudeA)) *
                    cos(radians(latitudeB)) *
                    pow(sin(longitudeDelta / 2), 2))
            .clamp(0.0, 1.0);

    return 2 *
        earthRadiusMeters *
        atan2(sqrt(haversine), sqrt(1 - haversine));
  }
}
