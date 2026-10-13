class MobileDevice {
  const MobileDevice({
    required this.id,
    required this.status,
    this.enrolledAt,
    this.lastSeenAt,
  });

  final String id;
  final String status;
  final DateTime? enrolledAt;
  final DateTime? lastSeenAt;

  factory MobileDevice.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    if (id.isEmpty) {
      throw const FormatException('The device response did not include a device ID.');
    }
    return MobileDevice(
      id: id,
      status: (json['status'] ?? '').toString(),
      enrolledAt: DateTime.tryParse((json['enrolledAt'] ?? '').toString()),
      lastSeenAt: DateTime.tryParse((json['lastSeenAt'] ?? '').toString()),
    );
  }
}
