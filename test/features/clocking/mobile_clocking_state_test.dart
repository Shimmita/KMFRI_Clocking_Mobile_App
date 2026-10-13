import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_clocking/features/authentication/model/mobile_device.dart';
import 'package:mobile_app_clocking/features/authentication/model/mobile_device_identity.dart';
import 'package:mobile_app_clocking/features/authentication/model/mobile_user.dart';
import 'package:mobile_app_clocking/features/authentication/service/mobile_api_service.dart';
import 'package:mobile_app_clocking/features/clocking/cubit/mobile_clocking_cubit.dart';
import 'package:mobile_app_clocking/features/clocking/cubit/mobile_clocking_state.dart';
import 'package:mobile_app_clocking/features/clocking/model/attendance_history_record.dart';
import 'package:mobile_app_clocking/features/clocking/model/clocking_record.dart';
import 'package:mobile_app_clocking/features/clocking/model/mobile_attendance_context.dart';
import 'package:mobile_app_clocking/features/clocking/model/mobile_holiday_status.dart';
import 'package:mobile_app_clocking/features/clocking/repository/mobile_clocking_repository.dart';

void main() {
  const context = MobileAttendanceContext(
    stationName: 'MOMBASA CENTRE',
    stationLatitude: -4.05,
    stationLongitude: 39.68,
    radiusMeters: 500,
    geofenceEnabled: true,
    locationRequired: true,
    nextAction: 'clock_in',
    canClockOutside: false,
  );

  ClockingRecord record({
    required String action,
    String syncStatus = 'pending',
  }) => ClockingRecord(
    type: action == 'clock_in' ? 'CLOCK IN' : 'CLOCK OUT',
    time: DateTime.utc(2026, 10, 5, 6),
    localRecordId: 'record-id',
    syncStatus: syncStatus,
  );

  group('MobileClockingState', () {
    test('offline event synchronization preserves the captured timestamp', () {
      final eventAt = DateTime.utc(2026, 10, 5, 6);
      final clockingRecord = ClockingRecord(
        type: 'CLOCK IN',
        time: eventAt,
        localRecordId: 'record-id',
        installationId: 'installation-id',
      );

      expect(clockingRecord.toSyncJson()['eventAt'], eventAt.toIso8601String());
    });

    test(
      'pending offline clock-in changes the next available action to clock out',
      () {
        final state = MobileClockingState(
          context: context,
          records: [record(action: 'clock_in')],
        );

        expect(state.nextAction, 'clock_out');
        expect(state.pendingCount, 1);
        expect(state.canClock, isTrue);
      },
    );

    test('out-of-order pending events block additional clock actions', () {
      final state = MobileClockingState(
        context: context,
        records: [record(action: 'clock_out')],
      );

      expect(state.nextAction, isNull);
      expect(state.canClock, isFalse);
    });

    test('a rejected attendance event does not block clocking', () {
      final state = MobileClockingState(
        context: context,
        records: [record(action: 'clock_in', syncStatus: 'rejected')],
      );

      expect(state.hasRejectedRecords, isTrue);
      expect(state.nextAction, 'clock_in');
      expect(state.canClock, isTrue);
    });

    test('sync authentication requirement is preserved and can be cleared', () {
      final state = MobileClockingState(requiresSyncAuthentication: true);

      expect(state.copyWith().requiresSyncAuthentication, isTrue);
      expect(
        state
            .copyWith(requiresSyncAuthentication: false)
            .requiresSyncAuthentication,
        isFalse,
      );
    });

    test('online clocking waits for the holiday check to complete', () {
      final state = MobileClockingState(context: context, isOnline: true);

      expect(state.canClock, isFalse);
      expect(state.copyWith(isHolidayStatusLoaded: true).canClock, isTrue);
    });

    test('a holiday blocks clocking', () {
      final state = MobileClockingState(
        context: context,
        isOnline: true,
        isHolidayStatusLoaded: true,
        holidayStatus: MobileHolidayStatus(
          isHoliday: true,
          date: DateTime.now(),
        ),
      );

      expect(state.canClock, isFalse);
    });

    test('an expired cached holiday does not block offline clocking', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final state = MobileClockingState(
        context: context,
        holidayStatus: MobileHolidayStatus(
          isHoliday: true,
          date: yesterday,
          checkedAt: yesterday,
        ),
      );

      expect(state.canClock, isTrue);
    });

    test('clocking history maps missed clock-outs to System', () {
      final record = AttendanceHistoryRecord.fromJson({
        'clock_in': '2026-10-06T06:30:00.000Z',
        'clock_out': null,
        'missedClockOut': true,
      });

      expect(record.clockOutLabel, 'System');
      expect(record.clockInLabel, isNotEmpty);
    });
  });

  test('attendance context represents an unlimited sync age as null', () {
    final loadedContext = MobileAttendanceContext.fromJson({
      'station': {'name': 'MOMBASA CENTRE'},
      'nextAction': 'clock_in',
      'maximumSyncAgeHours': null,
    });

    expect(loadedContext.maximumSyncAgeHours, isNull);
    expect(loadedContext.toJson()['maximumSyncAgeHours'], isNull);
  });

  test(
    'expired session keeps offline records pending and requests auth',
    () async {
      final user = MobileUser(
        id: 'user-id',
        name: 'Test User',
        email: 'user@example.com',
        role: 'employee',
        employeeId: 'EMP-1',
      );
      final repository = _UnauthorizedSyncRepository(user, context);
      final cubit = MobileClockingCubit(
        repository,
        user,
        const MobileDevice(id: 'device-id', status: 'ACTIVE'),
        const MobileDeviceIdentity(
          installationId: 'installation-id',
          deviceHash: 'device-hash',
          deviceName: 'Test Device',
          deviceModel: 'Test Model',
          deviceManufacturer: 'Test Manufacturer',
          deviceOS: 'Test OS',
          deviceOSVersion: '1',
          platform: 'test',
          appVersion: '1',
        ),
      );

      await cubit.initialize(isOnline: false);
      await cubit.updateConnectivity(true);

      expect(cubit.state.requiresSyncAuthentication, isTrue);
      expect(cubit.state.pendingCount, 1);
      expect(cubit.state.records.single.syncStatus, 'pending');
      await cubit.close();
    },
  );

  test('review retry requeues the original event while offline', () async {
    final user = MobileUser(
      id: 'user-id',
      name: 'Test User',
      email: 'user@example.com',
      role: 'employee',
      employeeId: 'EMP-1',
    );
    final repository = _UnauthorizedSyncRepository(
      user,
      context,
      initialSyncStatus: 'rejected',
    );
    final cubit = MobileClockingCubit(
      repository,
      user,
      const MobileDevice(id: 'device-id', status: 'ACTIVE'),
      const MobileDeviceIdentity(
        installationId: 'installation-id',
        deviceHash: 'device-hash',
        deviceName: 'Test Device',
        deviceModel: 'Test Model',
        deviceManufacturer: 'Test Manufacturer',
        deviceOS: 'Test OS',
        deviceOSVersion: '1',
        platform: 'test',
        appVersion: '1',
      ),
    );

    await cubit.initialize(isOnline: false);
    final capturedTime = cubit.state.records.single.time;
    await cubit.retrySynchronization('record-id');

    expect(cubit.state.records.single.syncStatus, 'pending');
    expect(cubit.state.records.single.time, capturedTime);
    expect(cubit.state.records.single.syncMessage, isNull);
    expect(cubit.state.canClock, isTrue);
    await cubit.close();
  });
}

class _UnauthorizedSyncRepository extends MobileClockingRepository {
  _UnauthorizedSyncRepository(
    this.user,
    this.attendanceContext, {
    String initialSyncStatus = 'pending',
  }) : records = [
         ClockingRecord(
           type: 'CLOCK IN',
           time: DateTime.utc(2026, 10, 5, 6),
           localRecordId: 'record-id',
           userId: user.id,
           installationId: 'installation-id',
           syncStatus: initialSyncStatus,
           syncMessage: initialSyncStatus == 'rejected'
               ? 'The previous sync was declined.'
               : null,
         ),
       ],
       super(MobileApiService());

  final MobileUser user;
  final MobileAttendanceContext attendanceContext;
  final List<ClockingRecord> records;

  @override
  Future<List<ClockingRecord>> loadRecords(String userId) async => records;

  @override
  Future<void> saveRecord(ClockingRecord record) async {
    final index = records.indexWhere(
      (saved) => saved.localRecordId == record.localRecordId,
    );
    if (index >= 0) records[index] = record;
  }

  @override
  Future<MobileAttendanceContext?> loadContext(String userId) async =>
      attendanceContext;

  @override
  Future<List<AttendanceHistoryRecord>> loadAttendanceHistory(
    String userId,
  ) async => const [];

  @override
  Future<MobileHolidayStatus?> loadHolidayStatus(String userId) async => null;

  @override
  Future<MobileAttendanceContext> refreshContext({
    required String userId,
    required MobileDeviceIdentity identity,
  }) async => attendanceContext;

  @override
  Future<void> synchronize(ClockingRecord record) async {
    throw const MobileApiException(message: 'Unauthorized', statusCode: 401);
  }

  @override
  Future<MobileUser> refreshUserProfile() async => user;

  @override
  Future<MobileHolidayStatus> refreshHolidayStatus(String userId) async =>
      MobileHolidayStatus(isHoliday: false, date: DateTime.now());

  @override
  Future<List<AttendanceHistoryRecord>> refreshAttendanceHistory(
    String userId,
  ) async => const [];
}
