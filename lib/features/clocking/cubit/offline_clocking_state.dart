import '../model/clocking_record.dart';

class OfflineClockingState {
  OfflineClockingState({
    this.isClockedIn = false,
    List<ClockingRecord> records = const [],
    this.lastActionMessage,
  }) : records = List.unmodifiable(records);

  final bool isClockedIn;
  final List<ClockingRecord> records;
  final String? lastActionMessage;
}
