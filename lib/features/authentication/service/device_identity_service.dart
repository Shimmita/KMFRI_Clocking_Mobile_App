import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../model/mobile_device_identity.dart';

class DeviceIdentityService {
  DeviceIdentityService({
    FlutterSecureStorage? storage,
    DeviceInfoPlugin? deviceInfo,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  static const _installationIdKey = 'kmfri.mobile.installation_id';

  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _deviceInfo;

  Future<MobileDeviceIdentity> getIdentity() async {
    final installationId = await _getInstallationId();
    final packageInfo = await PackageInfo.fromPlatform();
    final details = await _readPlatformDetails();
    final canonicalIdentity = [
      installationId,
      details.model,
      details.os,
      details.platform,
    ].join('|');

    return MobileDeviceIdentity(
      installationId: installationId,
      deviceHash: sha256.convert(utf8.encode(canonicalIdentity)).toString(),
      deviceName: details.name,
      deviceModel: details.model,
      deviceManufacturer: details.manufacturer,
      deviceOS: details.os,
      deviceOSVersion: details.osVersion,
      platform: details.platform,
      appVersion: packageInfo.version,
    );
  }

  Future<String> _getInstallationId() async {
    final stored = await _storage.read(key: _installationIdKey);
    if (stored != null && _isUuidV4(stored)) return stored;

    final id = generateUuidV4();
    await _storage.write(key: _installationIdKey, value: id);
    return id;
  }

  Future<_PlatformDeviceDetails> _readPlatformDetails() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await _deviceInfo.androidInfo;
      return _PlatformDeviceDetails(
        name: '${info.manufacturer} ${info.model}'.trim(),
        model: info.model,
        manufacturer: info.manufacturer,
        os: 'Android',
        osVersion: info.version.release,
        platform: 'android',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final info = await _deviceInfo.iosInfo;
      return _PlatformDeviceDetails(
        name: '${info.name} (${info.model})',
        model: info.model,
        manufacturer: 'Apple',
        os: info.systemName,
        osVersion: info.systemVersion,
        platform: 'ios',
      );
    }
    throw UnsupportedError('Mobile device enrollment is only supported on Android and iOS.');
  }

  bool _isUuidV4(String value) =>
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(value);

  static String generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

class _PlatformDeviceDetails {
  const _PlatformDeviceDetails({
    required this.name,
    required this.model,
    required this.manufacturer,
    required this.os,
    required this.osVersion,
    required this.platform,
  });

  final String name;
  final String model;
  final String manufacturer;
  final String os;
  final String osVersion;
  final String platform;
}
