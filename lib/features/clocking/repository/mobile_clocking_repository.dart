import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../../authentication/model/mobile_device_identity.dart';
import '../../authentication/model/mobile_user.dart';
import '../../authentication/service/device_identity_service.dart';
import '../../authentication/service/mobile_api_service.dart';
import '../model/attendance_history_record.dart';
import '../model/clocking_record.dart';
import '../model/mobile_attendance_context.dart';
import '../model/mobile_holiday_status.dart';
import '../service/geofence_distance.dart';

class MobileClockingRepository {
  MobileClockingRepository(
    this._api, {
    FlutterSecureStorage? storage,
    GeolocatorPlatform? geolocator,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final MobileApiService _api;
  final FlutterSecureStorage _storage;
  final GeolocatorPlatform _geolocator;

  String _contextKey(String userId) => 'kmfri.attendance.context.$userId';
  String _recordPrefix(String userId) => 'kmfri.attendance.record.$userId.';
  String _historyKey(String userId) => 'kmfri.attendance.history.$userId';
  String _holidayKey(String userId) => 'kmfri.attendance.holiday.$userId';
  String _recordKey(String userId, String recordId) =>
      '${_recordPrefix(userId)}$recordId';

  Future<List<ClockingRecord>> loadRecords(String userId) async {
    final allValues = await _storage.readAll();
    final prefix = _recordPrefix(userId);
    final records = <ClockingRecord>[];
    for (final entry in allValues.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      final decoded = jsonDecode(entry.value);
      if (decoded is Map<String, dynamic>) {
        records.add(ClockingRecord.fromJson(decoded));
      }
    }
    records.sort(_compareRecordTime);
    return List.unmodifiable(records);
  }

  Future<List<AttendanceHistoryRecord>> loadAttendanceHistory(
    String userId,
  ) async {
    final saved = await _storage.read(key: _historyKey(userId));
    if (saved == null) return const [];
    final decoded = jsonDecode(saved);
    if (decoded is! List) {
      throw const FormatException('The saved attendance history is invalid.');
    }
    return _parseAttendanceHistory(decoded);
  }

  Future<List<AttendanceHistoryRecord>> refreshAttendanceHistory(
    String userId,
  ) async {
    final jsonList = await _api.getAttendanceHistory();
    final records = _parseAttendanceHistory(jsonList);
    await _storage.write(key: _historyKey(userId), value: jsonEncode(jsonList));
    return List.unmodifiable(records);
  }

  Future<MobileHolidayStatus?> loadHolidayStatus(String userId) async {
    final saved = await _storage.read(key: _holidayKey(userId));
    if (saved == null) return null;
    final decoded = jsonDecode(saved);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The saved holiday status is invalid.');
    }
    return MobileHolidayStatus.fromJson(decoded);
  }

  Future<MobileHolidayStatus> refreshHolidayStatus(String userId) async {
    final response = await _api.getTodayHoliday();
    final checkedResponse = {
      ...response,
      'checkedAt': DateTime.now().toIso8601String(),
    };
    final holiday = MobileHolidayStatus.fromJson(checkedResponse);
    await _storage.write(
      key: _holidayKey(userId),
      value: jsonEncode(checkedResponse),
    );
    return holiday;
  }

  Future<MobileUser> refreshUserProfile() async {
    final profile = MobileUser.fromJson(await _api.getUserProfile());
    await _api.saveUser(profile);
    return profile;
  }

  List<AttendanceHistoryRecord> _parseAttendanceHistory(List<dynamic> entries) {
    final records = <AttendanceHistoryRecord>[];
    for (final entry in entries) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException(
          'The attendance history contains an invalid record.',
        );
      }
      records.add(AttendanceHistoryRecord.fromJson(entry));
    }
    return List.unmodifiable(records);
  }

  Future<MobileAttendanceContext?> loadContext(String userId) async {
    final saved = await _storage.read(key: _contextKey(userId));
    if (saved == null) return null;
    final decoded = jsonDecode(saved);
    if (decoded is! Map<String, dynamic>) {
      await _storage.delete(key: _contextKey(userId));
      return null;
    }
    return MobileAttendanceContext.fromJson(decoded);
  }

  Future<MobileAttendanceContext> refreshContext({
    required String userId,
    required MobileDeviceIdentity identity,
  }) async {
    final response = await _api.getAttendanceContext(identity.installationId);
    final context = MobileAttendanceContext.fromJson(response);
    await _storage.write(
      key: _contextKey(userId),
      value: jsonEncode(context.toJson()),
    );
    return context;
  }

  Future<ClockingRecord> createClockingRecord({
    required String userId,
    required String deviceId,
    required MobileDeviceIdentity identity,
    required MobileAttendanceContext context,
    required String action,
  }) async {
    if (!['clock_in', 'clock_out'].contains(action)) {
      throw ArgumentError.value(action, 'action', 'Unsupported clock action.');
    }
    final position = context.locationRequired || context.geofenceEnabled
        ? await _getCurrentPosition()
        : null;
    final isWithinGeofence = position == null
        ? !context.geofenceEnabled
        : _isWithinGeofence(context, position);
    if (context.geofenceEnabled &&
        !isWithinGeofence &&
        !context.canClockOutside) {
      throw StateError(
        'You are outside the assigned station premises and are not authorized to clock outside.',
      );
    }

    final time = DateTime.now().toUtc();
    final record = ClockingRecord(
      type: action == 'clock_in' ? 'CLOCK IN' : 'CLOCK OUT',
      time: time,
      localRecordId: DeviceIdentityService.generateUuidV4(),
      userId: userId,
      deviceId: deviceId,
      installationId: identity.installationId,
      station: context.stationName,
      latitude: position?.latitude,
      longitude: position?.longitude,
      syncStatus: 'pending',
      createdAt: time,
    );
    await saveRecord(record);
    return record;
  }

  Future<void> saveRecord(ClockingRecord record) async {
    await _storage.write(
      key: _recordKey(record.userId, record.localRecordId),
      value: jsonEncode(record.toJson()),
    );
  }

  Future<void> synchronize(ClockingRecord record) async {
    final response = await _api.synchronizeAttendance(record.toSyncJson());
    if (response['success'] != true || response['synced'] != true) {
      throw const FormatException(
        'KMFRI did not confirm synchronization of the attendance record.',
      );
    }
  }

  Future<void> reauthenticateForSynchronization({
    required String userId,
    required String deviceId,
    required MobileDeviceIdentity identity,
    required String password,
  }) => _api.reauthenticateForSynchronization(
    userId: userId,
    expectedDeviceId: deviceId,
    installationId: identity.installationId,
    password: password,
  );

  Future<void> retainRecentHistory(String userId) async {
    final records = await loadRecords(userId);
    final synced =
        records.where((record) => record.syncStatus == 'synced').toList()
          ..sort(_compareRecordTime);
    if (synced.length <= 100) return;
    for (final oldRecord in synced.take(synced.length - 100)) {
      await _storage.delete(key: _recordKey(userId, oldRecord.localRecordId));
    }
  }

  Future<Position?> ensureLocationAndGetPosition({
    bool promptIfDisabled = true,
  }) async {
    try {
      var serviceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (promptIfDisabled) {
          await _geolocator.openLocationSettings();
          serviceEnabled = await _geolocator.isLocationServiceEnabled();
        }
        if (!serviceEnabled) return null;
      }

      var permission = await _geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (promptIfDisabled) {
          permission = await _geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) {
        if (promptIfDisabled) {
          await _geolocator.openAppSettings();
        }
        return null;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        return await _geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Position?> getCurrentPositionOrNull() =>
      ensureLocationAndGetPosition(promptIfDisabled: false);

  int calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) => GeofenceDistance.metersBetween(lat1, lon1, lat2, lon2).round();

  Future<Position> _getCurrentPosition() async {
    var serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _geolocator.openLocationSettings();
      serviceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw StateError(
          'Turn on device location services to capture clocking details.',
        );
      }
    }

    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await _geolocator.openAppSettings();
      throw StateError(
        'Location permission is permanently denied. Please grant location permission in app settings.',
      );
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw StateError(
        'Location permission is required to capture clocking details.',
      );
    }

    return _geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  bool _isWithinGeofence(MobileAttendanceContext context, Position position) {
    if (!context.geofenceEnabled) return true;
    if (context.radiusMeters <= 0 ||
        (context.stationLatitude == 0 && context.stationLongitude == 0)) {
      throw StateError('The assigned station geofence is not configured.');
    }

    final distance = GeofenceDistance.metersBetween(
      position.latitude,
      position.longitude,
      context.stationLatitude,
      context.stationLongitude,
    );
    return distance <= context.radiusMeters;
  }

  int _compareRecordTime(ClockingRecord left, ClockingRecord right) {
    final leftTime = left.createdAt ?? left.time;
    final rightTime = right.createdAt ?? right.time;
    return leftTime.compareTo(rightTime);
  }
}
