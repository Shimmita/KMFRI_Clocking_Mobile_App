class AttendanceHistoryRecord {
  const AttendanceHistoryRecord({
    required this.date,
    required this.clockIn,
    required this.clockOut,
    required this.missedClockOut,
  });

  final DateTime date;
  final DateTime clockIn;
  final DateTime? clockOut;
  final bool missedClockOut;

  String get clockOutLabel =>
      clockOut == null || missedClockOut ? 'System' : _formatTime(clockOut!);

  factory AttendanceHistoryRecord.fromJson(Map<String, dynamic> json) {
    final clockIn = DateTime.tryParse((json['clock_in'] ?? '').toString());
    if (clockIn == null) {
      throw const FormatException(
        'The attendance history response included an invalid clock-in time.',
      );
    }

    final clockOutValue = json['clock_out'];
    final clockOut = clockOutValue == null
        ? null
        : DateTime.tryParse(clockOutValue.toString());
    if (clockOutValue != null && clockOut == null) {
      throw const FormatException(
        'The attendance history response included an invalid clock-out time.',
      );
    }
    return AttendanceHistoryRecord(
      date: clockIn,
      clockIn: clockIn,
      clockOut: clockOut,
      missedClockOut: json['missedClockOut'] == true,
    );
  }

  static String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
  }

  String get clockInLabel => _formatTime(clockIn);
}
