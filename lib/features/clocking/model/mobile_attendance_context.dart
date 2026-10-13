class MobileAttendanceContext {
  const MobileAttendanceContext({
    required this.stationName,
    required this.stationLatitude,
    required this.stationLongitude,
    required this.radiusMeters,
    required this.geofenceEnabled,
    required this.locationRequired,
    required this.nextAction,
    required this.canClockOutside,
    this.maximumSyncAgeHours,
  });

  final String stationName;
  final double stationLatitude;
  final double stationLongitude;
  final double radiusMeters;
  final bool geofenceEnabled;
  final bool locationRequired;
  final String nextAction;
  final bool canClockOutside;
  final int? maximumSyncAgeHours;

  static const List<Map<String, dynamic>> _fallbackStations = [
    {'name': 'MOMBASA CENTRE', 'lat': -4.0546356, 'lng': 39.6826, 'radiusMeters': 500},
    {'name': 'SHIMONI CENTRE', 'lat': -4.644, 'lng': 39.375, 'radiusMeters': 500},
    {'name': 'KISUMU CENTRE', 'lat': -0.059149, 'lng': 34.8066, 'radiusMeters': 500},
    {'name': 'KEGATI STATION', 'lat': -0.644496, 'lng': 34.7481, 'radiusMeters': 500},
    {'name': 'TURKANA STATION', 'lat': 3.08222, 'lng': 36.0749, 'radiusMeters': 500},
    {'name': 'NAIROBI STATION', 'lat': -1.24936, 'lng': 36.7968, 'radiusMeters': 500},
    {'name': 'NAIVASHA STATION', 'lat': -0.664008, 'lng': 36.4651, 'radiusMeters': 500},
    {'name': 'BARINGO STATION', 'lat': 0.604245, 'lng': 35.9773, 'radiusMeters': 500},
    {'name': 'SANGORO STATION', 'lat': -0.394861, 'lng': 34.7374, 'radiusMeters': 500},
    {'name': 'SAGANA CENTRE', 'lat': -0.669415, 'lng': 37.2061, 'radiusMeters': 500},
    {'name': 'GAZI STATION', 'lat': -4.0546356, 'lng': 39.6826, 'radiusMeters': 500},
    {'name': 'MUTONGA CENTER', 'lat': -4.0546356, 'lng': 39.6826, 'radiusMeters': 500},
  ];

  factory MobileAttendanceContext.fromJson(Map<String, dynamic> json) {
    final station = json['station'];
    if (station is! Map<String, dynamic>) {
      throw const FormatException('The attendance response did not include a station.');
    }
    final stationName = (station['name'] ?? '').toString();
    final nextAction = (json['nextAction'] ?? '').toString();
    if (stationName.isEmpty ||
        !['clock_in', 'clock_out'].contains(nextAction)) {
      throw const FormatException('The attendance context is incomplete.');
    }

    var lat = _asDouble(station['latitude'] ?? station['lat']);
    var lng = _asDouble(station['longitude'] ?? station['lng']);
    var radius = _asDouble(station['radiusMeters'] ?? json['radiusMeters']);

    if (lat == 0.0 && lng == 0.0) {
      final fallback = _fallbackStations.firstWhere(
        (s) => (s['name'] as String).toUpperCase() == stationName.toUpperCase(),
        orElse: () => const {},
      );
      if (fallback.isNotEmpty) {
        lat = _asDouble(fallback['lat']);
        lng = _asDouble(fallback['lng']);
        if (radius <= 0) radius = _asDouble(fallback['radiusMeters']);
      }
    }

    return MobileAttendanceContext(
      stationName: stationName,
      stationLatitude: lat,
      stationLongitude: lng,
      radiusMeters: radius > 0 ? radius : 500,
      geofenceEnabled: json['geofenceEnabled'] == true || json['geofence']?['enabled'] == true,
      locationRequired: json['locationRequired'] != false,
      nextAction: nextAction,
      canClockOutside: json['canClockOutside'] == true,
      maximumSyncAgeHours: _asInt(json['maximumSyncAgeHours']),
    );
  }

  Map<String, dynamic> toJson() => {
    'station': {
      'name': stationName,
      'latitude': stationLatitude,
      'longitude': stationLongitude,
      'radiusMeters': radiusMeters,
    },
    'geofenceEnabled': geofenceEnabled,
    'locationRequired': locationRequired,
    'nextAction': nextAction,
    'canClockOutside': canClockOutside,
    'maximumSyncAgeHours': maximumSyncAgeHours,
  };

  static double _asDouble(Object? value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  static int? _asInt(Object? value) => int.tryParse(value?.toString() ?? '');
}
