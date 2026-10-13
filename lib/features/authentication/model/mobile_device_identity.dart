class MobileDeviceIdentity {
  const MobileDeviceIdentity({
    required this.installationId,
    required this.deviceHash,
    required this.deviceName,
    required this.deviceModel,
    required this.deviceManufacturer,
    required this.deviceOS,
    required this.deviceOSVersion,
    required this.platform,
    required this.appVersion,
  });

  final String installationId;
  final String deviceHash;
  final String deviceName;
  final String deviceModel;
  final String deviceManufacturer;
  final String deviceOS;
  final String deviceOSVersion;
  final String platform;
  final String appVersion;

  Map<String, dynamic> toJson() => {
    'installationId': installationId,
    'deviceHash': deviceHash,
    'deviceName': deviceName,
    'deviceModel': deviceModel,
    'deviceManufacturer': deviceManufacturer,
    'deviceOS': deviceOS,
    'deviceOSVersion': deviceOSVersion,
    'platform': platform,
    'appVersion': appVersion,
  };
}
