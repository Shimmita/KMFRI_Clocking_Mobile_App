import '../model/clocking_record.dart';

class OfflineClockingRepository {
  bool _isClockedIn = false;
  final List<ClockingRecord> _records = [];

  bool get isClockedIn => _isClockedIn;
  List<ClockingRecord> get records => List.unmodifiable(_records);

  ClockingRecord clockIn() => _record('CLOCK IN', true);

  ClockingRecord clockOut() => _record('CLOCK OUT', false);

  ClockingRecord _record(String type, bool isClockedIn) {
    final record = ClockingRecord(type: type, time: DateTime.now());
    _isClockedIn = isClockedIn;
    _records.insert(0, record);
    return record;
  }
}
