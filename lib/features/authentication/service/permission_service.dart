import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService({
    LocalAuthentication? localAuth,
  }) : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Requests all required permissions on app launch.
  Future<void> requestLaunchPermissions() async {
    try {
      // 1. Request Location Permissions (GPS & Geofencing)
      await _requestLocationPermission();

      // 2. Check Biometric & Local Auth Security
      await _checkBiometricStatus();

      // 3. Request Notification Permission (if available)
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled on device.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
    }
  }

  Future<bool> _checkBiometricStatus() async {
    try {
      final canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } catch (e) {
      debugPrint('Biometric status check failed: $e');
      return false;
    }
  }
}
