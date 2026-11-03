import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_clocking/features/clocking/model/clocking_record.dart';

void main() {
  group('ClockingRecord location persistence', () {
    test('preserves captured coordinates and restores them from storage', () {
      final record = ClockingRecord(
        type: 'CLOCK IN',
        time: DateTime.utc(2026, 11, 3, 7, 30),
        localRecordId: 'record-1',
        latitude: -4.0546356,
        longitude: 39.6826,
        clockedOutside: true,
        withinPremise: false,
        outsideLocation: 'Mombasa.Outside',
        locationName: 'Mombasa.Outside',
      );

      final restored = ClockingRecord.fromJson(record.toJson());

      expect(restored.latitude, record.latitude);
      expect(restored.longitude, record.longitude);
      expect(restored.clockedOutside, isTrue);
      expect(restored.withinPremise, isFalse);
      expect(restored.outsideLocation, 'Mombasa.Outside');
      expect(restored.locationName, 'Mombasa.Outside');
    });

    test('sync payload uses the original captured coordinates', () {
      final record = ClockingRecord(
        type: 'CLOCK OUT',
        time: DateTime.utc(2026, 11, 3, 16, 30),
        localRecordId: 'record-2',
        latitude: -1.286389,
        longitude: 36.817223,
      );

      final payload = record.toSyncJson();

      expect(payload['userCoords'], {
        'latitude': -1.286389,
        'longitude': 36.817223,
      });
    });

    test('inside premise server metadata clears outside location', () {
      final record = ClockingRecord(
        type: 'CLOCK IN',
        time: DateTime.utc(2026, 11, 3, 7, 30),
        outsideLocation: 'Old Outside Place',
      );

      final resolved = record.copyWith(
        clearOutsideLocation: true,
        locationName: 'In Premise',
        clockedOutside: false,
        withinPremise: true,
      );

      expect(resolved.outsideLocation, isNull);
      expect(resolved.locationName, 'In Premise');
      expect(resolved.clockedOutside, isFalse);
      expect(resolved.withinPremise, isTrue);
    });
  });
}
