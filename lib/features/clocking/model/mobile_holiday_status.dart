class MobileHolidayStatus {
  const MobileHolidayStatus({
    required this.isHoliday,
    this.name = '',
    this.date,
    this.message = '',
    this.checkedAt,
  });

  final bool isHoliday;
  final String name;
  final DateTime? date;
  final String message;
  final DateTime? checkedAt;

  bool get isHolidayToday {
    if (!isHoliday) return false;
    final reference = date ?? checkedAt;
    if (reference == null) return true;
    final localDate = reference.toLocal();
    final now = DateTime.now();
    return localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
  }

  factory MobileHolidayStatus.fromJson(Map<String, dynamic> json) {
    final holiday = json['holiday'];
    final holidayMap = holiday is Map<String, dynamic> ? holiday : null;
    return MobileHolidayStatus(
      isHoliday: json['isHoliday'] == true,
      name: (holidayMap?['name'] ?? '').toString(),
      date: DateTime.tryParse((holidayMap?['date'] ?? '').toString()),
      message: (json['message'] ?? '').toString(),
      checkedAt: DateTime.tryParse((json['checkedAt'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'isHoliday': isHoliday,
    'holiday': {'name': name, 'date': date?.toIso8601String()},
    'message': message,
    'checkedAt': checkedAt?.toIso8601String(),
  };
}
