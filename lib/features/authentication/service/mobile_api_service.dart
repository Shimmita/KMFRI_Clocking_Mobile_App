import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../model/mobile_device.dart';
import '../model/mobile_device_identity.dart';
import '../model/mobile_user.dart';
import '../model/remembered_account.dart';

const String kmfriApiBaseUrl =
    'https://clocking.kmfri.go.ke/kmfri/attendance/api/v1';

class MobileApiException implements Exception {
  const MobileApiException({required this.message, this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}

class DeviceStatusResult {
  const DeviceStatusResult({required this.enrolled, this.device});

  final bool enrolled;
  final MobileDevice? device;
}

class MobileApiService {
  MobileApiService({FlutterSecureStorage? storage, HttpClient? httpClient})
    : _storage = storage ?? const FlutterSecureStorage(),
      _httpClient =
          httpClient ??
          (HttpClient()
            ..connectionTimeout = const Duration(seconds: 15)
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) {
                  return host.contains('kmfri.go.ke');
                });

  static const _cookieKey = 'kmfri.mobile.session_cookie';
  static const _userKey = 'kmfri.mobile.user';
  static const _deviceIdKey = 'kmfri.mobile.device_id';
  static const _onboardingKey = 'kmfri.mobile.onboarding_completed';
  static const _rememberedAccountsKey = 'kmfri.mobile.remembered_accounts';

  final FlutterSecureStorage _storage;
  final HttpClient _httpClient;

  Future<bool> isOnboardingCompleted() async {
    final value = await _storage.read(key: _onboardingKey);
    return value == 'true';
  }

  Future<void> setOnboardingCompleted() =>
      _storage.write(key: _onboardingKey, value: 'true');

  Future<MobileUser> signIn({
    required bool isStaff,
    required String username,
    required String password,
    required String installationId,
  }) async {
    final path = isStaff ? '/auth/signin-staff' : '/auth/signin';
    final body = isStaff
        ? {
            'userId': username.trim(),
            'password': password,
            'installationId': installationId,
          }
        : {
            'email': username.trim(),
            'password': password,
            'installationId': installationId,
          };
    final response = await _request('POST', path, body: body);
    final userJson =
        response['user'] ?? response['data'] ?? response['profile'] ?? response;
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException(
        'The sign-in response was not a valid user profile.',
      );
    }

    return MobileUser.fromJson(userJson);
  }

  Future<bool> isSessionValid() async {
    final response = await _request('GET', '/valid');
    return response['valid'] == true;
  }

  Future<DeviceStatusResult> checkDevice(String installationId) async {
    final response = await _request(
      'POST',
      '/mobile-app/device/status',
      body: {'installationId': installationId},
    );
    final deviceJson = response['device'];
    final enrolled = response['enrolled'] == true;
    final device = deviceJson is Map<String, dynamic>
        ? MobileDevice.fromJson(deviceJson)
        : null;
    if (enrolled && device != null) {
      await _storage.write(key: _deviceIdKey, value: device.id);
    }
    return DeviceStatusResult(enrolled: enrolled, device: device);
  }

  Future<MobileDevice> enrollDevice(MobileDeviceIdentity identity) async {
    final response = await _request(
      'POST',
      '/mobile-app/device/enroll',
      body: identity.toJson(),
    );
    final deviceJson = response['device'];
    if (response['success'] != true || deviceJson is! Map<String, dynamic>) {
      throw const FormatException('The enrollment response was incomplete.');
    }
    final device = MobileDevice.fromJson(deviceJson);
    await _storage.write(key: _deviceIdKey, value: device.id);
    return device;
  }

  Future<Map<String, dynamic>> getAttendanceContext(String installationId) =>
      _request(
        'POST',
        '/mobile-app/attendance/context',
        body: {'installationId': installationId},
      );

  Future<List<dynamic>> getAttendanceHistory() async {
    return _requestList('GET', '/user/attendance/history?limit=7');
  }

  Future<Map<String, dynamic>> getUserProfile() =>
      _request('GET', '/user/profile');

  Future<Map<String, dynamic>> getTodayHoliday() =>
      _request('GET', '/holidays/today');

  Future<Map<String, dynamic>> synchronizeAttendance(
    Map<String, dynamic> record,
  ) => _request('POST', '/mobile-app/attendance/sync', body: record);

  Future<void> reauthenticateForSynchronization({
    required String userId,
    required String expectedDeviceId,
    required String installationId,
    required String password,
  }) async {
    final account = await readRememberedAccount(userId);
    if (account == null) {
      throw const MobileApiException(
        message: 'This account is not saved on this device. Sign in again.',
      );
    }

    final isStaff = account.usesStaffSignIn;
    final username = account.authUsername.isNotEmpty
        ? account.authUsername
        : isStaff
        ? account.identifier
        : account.email;
    if (username.isEmpty) {
      throw const MobileApiException(
        message: 'The saved account is missing its sign-in identifier.',
      );
    }

    final user = await signIn(
      isStaff: isStaff,
      username: username,
      password: password,
      installationId: installationId,
    );
    if (user.id != userId) {
      await clearSession();
      throw const MobileApiException(
        message:
            'The authenticated account does not match this device account.',
      );
    }

    final deviceResult = await checkDevice(installationId);
    if (!deviceResult.enrolled || deviceResult.device?.id != expectedDeviceId) {
      await clearSession();
      throw const MobileApiException(
        message: 'This device is no longer authorized for this account.',
      );
    }

    await saveUser(user);
    await saveRememberedAccount(
      user: user,
      password: password,
      deviceId: deviceResult.device!.id,
      installationId: installationId,
      authUsername: username,
      isStaff: isStaff,
    );
  }

  Future<void> signOut() async {
    await _request('POST', '/user/signout', body: const {});
    await clearSession();
  }

  Future<void> saveUser(MobileUser user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  Future<MobileUser?> readUser() async {
    final json = await _storage.read(key: _userKey);
    if (json == null) return null;
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      await _storage.delete(key: _userKey);
      return null;
    }
    return MobileUser.fromStorageJson(decoded);
  }

  Future<void> saveRememberedAccount({
    required MobileUser user,
    required String password,
    required String deviceId,
    required String installationId,
    required String authUsername,
    required bool isStaff,
  }) async {
    final salt = _generateSalt();
    final verifier = _derivePasswordVerifier(password, salt);
    final accounts = await readRememberedAccounts();
    final account = RememberedAccount(
      userId: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      identifier: user.employeeId.isNotEmpty ? user.employeeId : user.email,
      salt: base64Encode(salt),
      verifier: base64Encode(verifier),
      deviceId: deviceId,
      installationId: installationId,
      userProfile: user.toJson(),
      authUsername: authUsername,
      authIsStaff: isStaff,
    );
    final filtered = accounts
        .where((entry) => entry.userId != user.id)
        .toList();
    filtered.add(account);
    await _storage.write(
      key: _rememberedAccountsKey,
      value: jsonEncode(filtered.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<List<RememberedAccount>> readRememberedAccounts() async {
    final raw = await _storage.read(key: _rememberedAccountsKey);
    if (raw == null || raw.trim().isEmpty) return const <RememberedAccount>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <RememberedAccount>[];

    final accounts = <RememberedAccount>[];
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        accounts.add(RememberedAccount.fromJson(item));
      } else if (item is Map) {
        accounts.add(
          RememberedAccount.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
    return accounts;
  }

  Future<RememberedAccount?> readRememberedAccount(String userId) async {
    final accounts = await readRememberedAccounts();
    for (final account in accounts) {
      if (account.userId == userId) return account;
    }
    return null;
  }

  Future<bool> verifyRememberedAccountPassword(
    String userId,
    String password,
  ) async {
    final account = await readRememberedAccount(userId);
    if (account == null || account.salt.isEmpty || account.verifier.isEmpty) {
      return false;
    }

    try {
      final expected = _derivePasswordVerifier(
        password,
        base64Decode(account.salt),
      );
      final actual = base64Decode(account.verifier);
      return listEquals(expected, actual);
    } on FormatException {
      return false;
    }
  }

  Future<void> removeRememberedAccount(String userId) async {
    final filtered = (await readRememberedAccounts())
        .where((account) => account.userId != userId)
        .toList();
    if (filtered.isEmpty) {
      await _storage.delete(key: _rememberedAccountsKey);
      return;
    }
    await _storage.write(
      key: _rememberedAccountsKey,
      value: jsonEncode(filtered.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<String?> readDeviceId() => _storage.read(key: _deviceIdKey);

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _cookieKey),
      _storage.delete(key: _userKey),
      _storage.delete(key: _deviceIdKey),
    ]);
  }

  List<int> _generateSalt() {
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256));
  }

  List<int> _derivePasswordVerifier(String password, List<int> salt) {
    const iterations = 120000;
    const keyLength = 32;
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);
    final output = <int>[];

    for (
      var blockIndex = 1;
      blockIndex <= ((keyLength + 31) ~/ 32);
      blockIndex++
    ) {
      var u = _hmacSha256(hmac, [...salt, ..._blockFromIndex(blockIndex)]);
      var t = List<int>.from(u);
      for (var iteration = 1; iteration < iterations; iteration++) {
        u = _hmacSha256(hmac, u);
        for (var byteIndex = 0; byteIndex < t.length; byteIndex++) {
          t[byteIndex] ^= u[byteIndex];
        }
      }
      output.addAll(t);
    }

    return output.take(keyLength).toList();
  }

  List<int> _hmacSha256(Hmac hmac, List<int> data) => hmac.convert(data).bytes;

  List<int> _blockFromIndex(int blockIndex) {
    final block = List<int>.filled(4, 0, growable: false);
    block[0] = (blockIndex >> 24) & 0xff;
    block[1] = (blockIndex >> 16) & 0xff;
    block[2] = (blockIndex >> 8) & 0xff;
    block[3] = blockIndex & 0xff;
    return block;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final decoded = await _requestJson(method, path, body: body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException(
      'The KMFRI server returned an unexpected response.',
    );
  }

  Future<List<dynamic>> _requestList(String method, String path) async {
    final decoded = await _requestJson(method, path);
    if (decoded is List<dynamic>) return decoded;
    throw const FormatException(
      'The KMFRI server returned an unexpected attendance history.',
    );
  }

  Future<Object?> _requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = await _httpClient
        .openUrl(method, Uri.parse('$kmfriApiBaseUrl$path'))
        .timeout(const Duration(seconds: 20));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, 'KMFRI-Clocking-Mobile');
    final cookie = await _storage.read(key: _cookieKey);
    if (cookie != null && cookie.isNotEmpty) {
      request.headers.set(HttpHeaders.cookieHeader, cookie);
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

    final response = await request.close().timeout(const Duration(seconds: 20));
    await _saveSessionCookie(response);
    final responseText = await response.transform(utf8.decoder).join();
    final decoded = responseText.isEmpty
        ? <String, dynamic>{}
        : path == '/user/signout' &&
              responseText.trim() == 'logged out successfully'
        ? <String, dynamic>{'message': responseText.trim()}
        : jsonDecode(responseText);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = decoded is Map<String, dynamic> ? decoded : const {};
      throw MobileApiException(
        message: (errorBody['message'] ?? 'KMFRI service request failed.')
            .toString(),
        code: errorBody['code']?.toString(),
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  Future<void> _saveSessionCookie(HttpClientResponse response) async {
    final setCookieHeaders =
        response.headers[HttpHeaders.setCookieHeader] ?? const <String>[];
    for (final header in setCookieHeaders) {
      final cookie = header.split(';').first.trim();
      if (cookie.isEmpty || cookie.endsWith('=')) {
        await _storage.delete(key: _cookieKey);
      } else {
        await _storage.write(key: _cookieKey, value: cookie);
      }
    }
  }
}
