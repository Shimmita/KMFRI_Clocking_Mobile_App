import '../model/mobile_device.dart';
import '../model/mobile_device_identity.dart';
import '../model/mobile_user.dart';
import '../model/remembered_account.dart';
import '../service/device_identity_service.dart';
import '../service/mobile_api_service.dart';

class MobileAuthRepository {
  MobileAuthRepository(this._api, this._deviceIdentityService);

  final MobileApiService _api;
  final DeviceIdentityService _deviceIdentityService;

  Future<MobileDeviceIdentity> getDeviceIdentity() =>
      _deviceIdentityService.getIdentity();

  Future<MobileUser> signIn({
    required bool isStaff,
    required String username,
    required String password,
    required String installationId,
  }) => _api.signIn(
    isStaff: isStaff,
    username: username,
    password: password,
    installationId: installationId,
  );

  Future<bool> isSessionValid() => _api.isSessionValid();

  Future<DeviceStatusResult> checkDevice(String installationId) =>
      _api.checkDevice(installationId);

  Future<MobileDevice> enrollDevice(MobileDeviceIdentity identity) =>
      _api.enrollDevice(identity);

  Future<MobileUser?> readUser() => _api.readUser();

  Future<String?> readDeviceId() => _api.readDeviceId();

  Future<void> saveUser(MobileUser user) => _api.saveUser(user);

  Future<void> saveRememberedAccount({
    required MobileUser user,
    required String password,
    required String deviceId,
    required String installationId,
    required String authUsername,
    required bool isStaff,
  }) => _api.saveRememberedAccount(
    user: user,
    password: password,
    deviceId: deviceId,
    installationId: installationId,
    authUsername: authUsername,
    isStaff: isStaff,
  );

  Future<List<RememberedAccount>> readRememberedAccounts() =>
      _api.readRememberedAccounts();

  Future<RememberedAccount?> readRememberedAccount(String userId) =>
      _api.readRememberedAccount(userId);

  Future<bool> verifyRememberedAccountPassword(
    String userId,
    String password,
  ) => _api.verifyRememberedAccountPassword(userId, password);

  Future<void> removeRememberedAccount(String userId) =>
      _api.removeRememberedAccount(userId);

  Future<bool> isOnboardingCompleted() => _api.isOnboardingCompleted();

  Future<void> setOnboardingCompleted() => _api.setOnboardingCompleted();

  Future<void> clearSession() => _api.clearSession();

  Future<void> signOut() => _api.signOut();
}
