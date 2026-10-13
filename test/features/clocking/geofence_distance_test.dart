import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_clocking/features/clocking/service/geofence_distance.dart';

void main() {
  group('GeofenceDistance', () {
    test('measures coordinates at full GPS precision', () {
      const stationLatitude = -4.0546356;
      const stationLongitude = 39.6826;

      final distance = GeofenceDistance.metersBetween(
        stationLatitude,
        stationLongitude,
        stationLatitude + 0.00001,
        stationLongitude,
      );

      expect(distance, closeTo(1.11, 0.02));
    });

    test('matches the expected distance from Mombasa Centre coordinates', () {
      final distance = GeofenceDistance.metersBetween(
        -4.0546356,
        39.6826,
        -4.0536356,
        39.6826,
      );

      expect(distance, closeTo(111.2, 0.2));
    });

    test('returns zero for identical coordinates', () {
      expect(
        GeofenceDistance.metersBetween(
          -4.0546356,
          39.6826,
          -4.0546356,
          39.6826,
        ),
        0,
      );
    });
  });
}
