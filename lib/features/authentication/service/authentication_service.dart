import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../model/authentication_result.dart';

class AuthenticationService {
  AuthenticationService([LocalAuthentication? authentication])
      : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  Future<AuthenticationResult> authenticate() async {
    try {
      if (!await _authentication.isDeviceSupported()) {
        return AuthenticationResult.unsupported;
      }

      final authenticated = await _authentication.authenticate(
        localizedReason: 'Authenticate to unlock your KMFRI account securely.',
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
      return authenticated
          ? AuthenticationResult.authenticated
          : AuthenticationResult.cancelled;
    } on LocalAuthException catch (error) {
      debugPrint('Local authentication error: ${error.code}');
      return AuthenticationResult.failed;
    } catch (error) {
      debugPrint('Authentication error: $error');
      return AuthenticationResult.failed;
    }
  }
}
