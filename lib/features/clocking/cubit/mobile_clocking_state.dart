import '../model/attendance_history_record.dart';
import '../model/clocking_record.dart';
import '../model/mobile_attendance_context.dart';
import '../model/mobile_holiday_status.dart';

class MobileClockingState {
  MobileClockingState({
    this.context,
    List<ClockingRecord> records = const [],
    List<AttendanceHistoryRecord> history = const [],
    this.holidayStatus,
    this.isHolidayStatusLoaded = false,
    this.isAccountActive,
    this.isOnLeave = false,
    this.isLoading = false,
    this.isClocking = false,
    this.isSyncing = false,
    this.isOnline = false,
    this.requiresSyncAuthentication = false,
    this.userLatitude,
    this.userLongitude,
    this.distanceMeters,
    this.isWithinGeofence,
    this.errorMessage,
    this.lastActionMessage,
  }) : records = List.unmodifiable(records),
       history = List.unmodifiable(history);

  final MobileAttendanceContext? context;
  final List<ClockingRecord> records;
  final List<AttendanceHistoryRecord> history;
  final MobileHolidayStatus? holidayStatus;
  final bool isHolidayStatusLoaded;
  final bool? isAccountActive;
  final bool isOnLeave;
  final bool isLoading;
  final bool isClocking;
  final bool isSyncing;
  final bool isOnline;
  final bool requiresSyncAuthentication;
  final double? userLatitude;
  final double? userLongitude;
  final int? distanceMeters;
  final bool? isWithinGeofence;
  final String? errorMessage;
  final String? lastActionMessage;

  bool get hasLocation => userLatitude != null && userLongitude != null;

  bool get canProceedWithLocation {
    if (context == null) return false;
    if (context!.canClockOutside) return true;
    if (isWithinGeofence == false) return false;
    return true;
  }

  int get pendingCount =>
      records.where((record) => record.syncStatus == 'pending').length;

  bool get hasRejectedRecords =>
      records.any((record) => record.syncStatus == 'rejected');

  String? get nextAction {
    final currentContext = context;
    if (currentContext == null) return null;
    var action = currentContext.nextAction;
    for (final record in records) {
      if (record.syncStatus != 'pending') continue;
      if (record.action != action) return null;
      action = action == 'clock_in' ? 'clock_out' : 'clock_in';
    }
    return action;
  }

  bool get canClock =>
      context != null &&
      !(isOnline && !isHolidayStatusLoaded) &&
      holidayStatus?.isHolidayToday != true &&
      isAccountActive != false &&
      !isOnLeave &&
      !isLoading &&
      !isClocking &&
      !isSyncing &&
      nextAction != null &&
      canProceedWithLocation;

  MobileClockingState copyWith({
    MobileAttendanceContext? context,
    List<ClockingRecord>? records,
    List<AttendanceHistoryRecord>? history,
    MobileHolidayStatus? holidayStatus,
    bool? isHolidayStatusLoaded,
    bool? isAccountActive,
    bool? isOnLeave,
    bool? isLoading,
    bool? isClocking,
    bool? isSyncing,
    bool? isOnline,
    bool? requiresSyncAuthentication,
    double? userLatitude,
    double? userLongitude,
    int? distanceMeters,
    bool? isWithinGeofence,
    String? errorMessage,
    String? lastActionMessage,
    bool clearError = false,
    bool clearLastActionMessage = false,
    bool clearContext = false,
    bool clearHolidayStatus = false,
    bool clearLocation = false,
  }) => MobileClockingState(
    context: clearContext ? null : context ?? this.context,
    records: records ?? this.records,
    history: history ?? this.history,
    holidayStatus: clearHolidayStatus
        ? null
        : holidayStatus ?? this.holidayStatus,
    isHolidayStatusLoaded: isHolidayStatusLoaded ?? this.isHolidayStatusLoaded,
    isAccountActive: isAccountActive ?? this.isAccountActive,
    isOnLeave: isOnLeave ?? this.isOnLeave,
    isLoading: isLoading ?? this.isLoading,
    isClocking: isClocking ?? this.isClocking,
    isSyncing: isSyncing ?? this.isSyncing,
    isOnline: isOnline ?? this.isOnline,
    requiresSyncAuthentication:
        requiresSyncAuthentication ?? this.requiresSyncAuthentication,
    userLatitude: clearLocation ? null : userLatitude ?? this.userLatitude,
    userLongitude: clearLocation ? null : userLongitude ?? this.userLongitude,
    distanceMeters:
        clearLocation ? null : distanceMeters ?? this.distanceMeters,
    isWithinGeofence:
        clearLocation ? null : isWithinGeofence ?? this.isWithinGeofence,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    lastActionMessage: clearLastActionMessage
        ? null
        : lastActionMessage ?? this.lastActionMessage,
  );
}
