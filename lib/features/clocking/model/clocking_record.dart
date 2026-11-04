class ClockingRecord {
  const ClockingRecord({
    required this.type,
    required this.time,
    this.localRecordId = '',
    this.userId = '',
    this.deviceId = '',
    this.installationId = '',
    this.station = '',
    this.latitude,
    this.longitude,
    this.outsideLocation,
    this.locationName,
    this.clockedOutside = false,
    this.withinPremise,
    this.syncStatus = 'pending',
    this.syncMessage,
    this.createdAt,
  });

  final String type;
  final DateTime time;
  final String localRecordId;
  final String userId;
  final String deviceId;
  final String installationId;
  final String station;
  final double? latitude;
  final double? longitude;
  final String? outsideLocation;
  final String? locationName;
  final bool clockedOutside;
  final bool? withinPremise;
  final String syncStatus;
  final String? syncMessage;
  final DateTime? createdAt;

  String get action => type == 'CLOCK OUT' ? 'clock_out' : 'clock_in';
  bool get isPending => syncStatus == 'pending';

  factory ClockingRecord.fromJson(Map<String, dynamic> json) {
    final eventAt = DateTime.tryParse((json['eventAt'] ?? '').toString());
    if (eventAt == null) {
      throw const FormatException(
        'The saved clocking record has an invalid time.',
      );
    }
    return ClockingRecord(
      type: (json['type'] ?? '').toString(),
      time: eventAt,
      localRecordId: (json['localRecordId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      deviceId: (json['deviceId'] ?? '').toString(),
      installationId: (json['installationId'] ?? '').toString(),
      station: (json['station'] ?? '').toString(),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      outsideLocation: json['outsideLocation']?.toString(),
      locationName: json['locationName']?.toString(),
      clockedOutside: json['clockedOutside'] == true,
      withinPremise: json['withinPremise'] == null
          ? null
          : json['withinPremise'] == true,
      syncStatus: (json['syncStatus'] ?? 'pending').toString(),
      syncMessage: json['syncMessage']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'eventAt': time.toUtc().toIso8601String(),
    'localRecordId': localRecordId,
    'userId': userId,
    'deviceId': deviceId,
    'installationId': installationId,
    'station': station,
    'latitude': latitude,
    'longitude': longitude,
    'outsideLocation': outsideLocation,
    'locationName': locationName,
    'clockedOutside': clockedOutside,
    'withinPremise': withinPremise,
    'syncStatus': syncStatus,
    'syncMessage': syncMessage,
    'createdAt': (createdAt ?? time).toUtc().toIso8601String(),
  };

  Map<String, dynamic> toSyncJson() => {
    'installationId': installationId,
    'localRecordId': localRecordId,
    'action': action,
    'eventAt': time.toUtc().toIso8601String(),
    'selectedStation': station,
    'userCoords': {'latitude': latitude, 'longitude': longitude},
    'outsideLocation': outsideLocation ?? syncMessage ?? '',
    'clockInLocationName': withinPremise == true
        ? 'IN PREMISE'
        : (outsideLocation ?? syncMessage ?? ''),
    'clockOutLocationName': withinPremise == true
        ? 'IN PREMISE'
        : (outsideLocation ?? syncMessage ?? ''),
    'withinPremise': withinPremise,
    'clockedOutside': clockedOutside,
  };

  ClockingRecord copyWith({
    String? outsideLocation,
    bool clearOutsideLocation = false,
    String? locationName,
    bool clearLocationName = false,
    bool? clockedOutside,
    bool? withinPremise,
    bool clearWithinPremise = false,
    String? syncStatus,
    String? syncMessage,
    bool clearSyncMessage = false,
  }) => ClockingRecord(
    type: type,
    time: time,
    localRecordId: localRecordId,
    userId: userId,
    deviceId: deviceId,
    installationId: installationId,
    station: station,
    latitude: latitude,
    longitude: longitude,
    outsideLocation: clearOutsideLocation
        ? null
        : outsideLocation ?? this.outsideLocation,
    locationName: clearLocationName ? null : locationName ?? this.locationName,
    clockedOutside: clockedOutside ?? this.clockedOutside,
    withinPremise: clearWithinPremise
        ? null
        : withinPremise ?? this.withinPremise,
    syncStatus: syncStatus ?? this.syncStatus,
    syncMessage: clearSyncMessage ? null : syncMessage ?? this.syncMessage,
    createdAt: createdAt,
  );

  static double? _asDouble(Object? value) =>
      value == null ? null : double.tryParse(value.toString());
}
