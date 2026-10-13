import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/authentication_result.dart';
import '../model/mobile_device.dart';
import '../model/remembered_account.dart';
import '../repository/authentication_repository.dart';
import '../repository/mobile_auth_repository.dart';
import '../service/mobile_api_service.dart';
import '../service/permission_service.dart';
import 'mobile_auth_state.dart';

class MobileAuthCubit extends Cubit<MobileAuthState> {
  MobileAuthCubit(
    this._repository,
    this._localAuthentication, {
    PermissionService? permissionService,
  }) : _permissionService = permissionService ?? PermissionService(),
       super(const MobileAuthState());

  final MobileAuthRepository _repository;
  final AuthenticationRepository _localAuthentication;
  final PermissionService _permissionService;

  MobileAuthState? _postOnboardingState;
  String? _pendingPassword;
  String? _pendingUsername;
  bool? _pendingIsStaff;

  Future<void> initialize({required bool isOnline}) async {
    emit(const MobileAuthState(isBusy: true));
    try {
      // 1. Request required app permissions on launch
      await _permissionService.requestLaunchPermissions();

      // 2. Check onboarding status
      final onboardingCompleted = await _repository.isOnboardingCompleted();
      final identity = await _repository.getDeviceIdentity();

      final targetState = await _evaluateSession(isOnline: isOnline);
      _postOnboardingState = targetState;

      if (!onboardingCompleted) {
        // Show onboarding tutorial on first ever launch
        emit(
          MobileAuthState(
            phase: MobileAuthPhase.onboardingRequired,
            identity: identity,
            isOffline: !isOnline,
          ),
        );
      } else {
        // Skip onboarding if already completed: if logged in, go straight to dashboard!
        emit(targetState);
      }
    } catch (error) {
      emit(
        MobileAuthState(
          phase: MobileAuthPhase.signedOut,
          errorMessage: 'Unable to initialize app session: $error',
          isOffline: !isOnline,
        ),
      );
    }
  }

  Future<MobileAuthState> _evaluateSession({required bool isOnline}) async {
    try {
      final user = await _repository.readUser();
      final savedDeviceId = await _repository.readDeviceId();
      final identity = await _repository.getDeviceIdentity();

      if (user == null || (!isOnline && savedDeviceId == null)) {
        if (user != null || savedDeviceId != null) {
          await _repository.clearSession();
        }
        return MobileAuthState(
          phase: MobileAuthPhase.signedOut,
          identity: identity,
          isOffline: !isOnline,
          errorMessage: isOnline
              ? null
              : 'First-time sign in requires an internet connection.',
        );
      }

      var deviceId = savedDeviceId;
      if (isOnline) {
        final validSession = await _repository.isSessionValid();
        if (!validSession) {
          await _repository.clearSession();
          return MobileAuthState(
            phase: MobileAuthPhase.signedOut,
            identity: identity,
            errorMessage: 'Your session expired. Please sign in again.',
          );
        }

        final result = await _repository.checkDevice(identity.installationId);
        if (!result.enrolled) {
          return MobileAuthState(
            phase: MobileAuthPhase.enrollmentRequired,
            user: user,
            identity: identity,
          );
        }
        final device = result.device!;
        if (deviceId != null && deviceId != device.id) {
          await _repository.clearSession();
          return MobileAuthState(
            phase: MobileAuthPhase.signedOut,
            identity: identity,
            errorMessage: 'Device verification failed. Contact KMFRI support if this phone was replaced.',
          );
        }
        deviceId = device.id;
      }

      final localResult = await _localAuthentication.authenticate();
      if (localResult != AuthenticationResult.authenticated) {
        return MobileAuthState(
          phase: MobileAuthPhase.signedOut,
          identity: identity,
          isOffline: !isOnline,
          errorMessage: _localAuthenticationMessage(localResult),
        );
      }

      if (deviceId == null) {
        await _repository.clearSession();
        return MobileAuthState(
          phase: MobileAuthPhase.signedOut,
          identity: identity,
          isOffline: !isOnline,
          errorMessage: 'This device is not enrolled. Sign in while online.',
        );
      }

      return MobileAuthState(
        phase: MobileAuthPhase.signedIn,
        user: user,
        identity: identity,
        device: MobileDevice(id: deviceId, status: 'ACTIVE'),
        isOffline: !isOnline,
      );
    } on MobileApiException catch (error) {
      if (_canUseOfflineSession(error) && !isClosed) {
        final offline = await _getOfflineSessionState();
        if (offline != null) return offline;
      }
      await _repository.clearSession();
      return MobileAuthState(
        phase: MobileAuthPhase.signedOut,
        errorMessage: error.message,
        isOffline: !isOnline,
      );
    } catch (_) {
      final offline = await _getOfflineSessionState();
      return offline ??
          MobileAuthState(
            phase: MobileAuthPhase.signedOut,
            isOffline: !isOnline,
            errorMessage: 'First-time sign in requires an internet connection.',
          );
    }
  }

  Future<List<RememberedAccount>> loadRememberedAccounts() =>
      _repository.readRememberedAccounts();

  Future<void> continueWithRememberedAccount({
    required bool isOnline,
    required String userId,
    required String password,
  }) async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final account = await _repository.readRememberedAccount(userId);
      if (account == null) {
        emit(
          state.copyWith(
            phase: MobileAuthPhase.signedOut,
            isBusy: false,
            isOffline: !isOnline,
            errorMessage: 'This account is no longer available on this device.',
          ),
        );
        return;
      }

      final passwordValid = await _repository.verifyRememberedAccountPassword(
        userId,
        password,
      );
      if (!passwordValid) {
        emit(
          state.copyWith(
            phase: MobileAuthPhase.signedOut,
            isBusy: false,
            isOffline: !isOnline,
            errorMessage: 'The password did not match this saved account.',
          ),
        );
        return;
      }

      final identity = await _repository.getDeviceIdentity();
      if (account.installationId.isNotEmpty &&
          account.installationId != identity.installationId) {
        emit(
          state.copyWith(
            phase: MobileAuthPhase.signedOut,
            isBusy: false,
            isOffline: !isOnline,
            errorMessage:
                'This remembered account is registered to a different device.',
          ),
        );
        return;
      }

      final localResult = await _localAuthentication.authenticate();
      if (localResult != AuthenticationResult.authenticated) {
        _clearPendingCredentials();
        await _repository.clearSession();
        emit(
          state.copyWith(
            phase: MobileAuthPhase.signedOut,
            isBusy: false,
            isOffline: !isOnline,
            errorMessage: _localAuthenticationMessage(localResult),
          ),
        );
        return;
      }

      final authIsStaff = account.usesStaffSignIn;
      final username = account.authUsername.isNotEmpty
          ? account.authUsername
          : authIsStaff
          ? account.identifier
          : account.email;

      if (isOnline) {
        final authenticatedUser = await _repository.signIn(
          isStaff: authIsStaff,
          username: username,
          password: password,
          installationId: identity.installationId,
        );
        if (authenticatedUser.id != account.userId) {
          await _repository.clearSession();
          emit(
            state.copyWith(
              phase: MobileAuthPhase.signedOut,
              isBusy: false,
              isOffline: false,
              errorMessage:
                  'The online account does not match this saved account.',
            ),
          );
          return;
        }

        final result = await _repository.checkDevice(identity.installationId);
        if (!result.enrolled || result.device == null) {
          _pendingPassword = password;
          _pendingUsername = username;
          _pendingIsStaff = authIsStaff;
          emit(
            MobileAuthState(
              phase: MobileAuthPhase.enrollmentRequired,
              user: authenticatedUser,
              identity: identity,
            ),
          );
          return;
        }
        if (account.deviceId.isNotEmpty &&
            account.deviceId != result.device!.id) {
          await _repository.clearSession();
          emit(
            state.copyWith(
              phase: MobileAuthPhase.signedOut,
              isBusy: false,
              isOffline: false,
              errorMessage: 'Device verification failed. Contact KMFRI support if this phone was replaced.',
            ),
          );
          return;
        }

        await _repository.saveUser(authenticatedUser);
        await _repository.saveRememberedAccount(
          user: authenticatedUser,
          password: password,
          deviceId: result.device!.id,
          installationId: identity.installationId,
          authUsername: username,
          isStaff: authIsStaff,
        );
        _clearPendingCredentials();
        emit(
          MobileAuthState(
            phase: MobileAuthPhase.signedIn,
            user: authenticatedUser,
            identity: identity,
            device: result.device,
          ),
        );
        return;
      }

      final savedUser = await _repository.readUser() ?? account.toMobileUser();
      final deviceId = account.deviceId.isNotEmpty
          ? account.deviceId
          : await _repository.readDeviceId();
      if (savedUser.id != account.userId || deviceId == null) {
        emit(
          state.copyWith(
            phase: MobileAuthPhase.signedOut,
            isBusy: false,
            isOffline: true,
            errorMessage: 'This account has no saved device enrollment for offline access. Connect to the internet to verify this device.',
          ),
        );
        return;
      }

      emit(
        MobileAuthState(
          phase: MobileAuthPhase.signedIn,
          user: savedUser,
          identity: identity,
          device: MobileDevice(id: deviceId, status: 'ACTIVE'),
          isOffline: true,
        ),
      );
    } catch (error) {
      _clearPendingCredentials();
      emit(
        state.copyWith(
          phase: MobileAuthPhase.signedOut,
          isBusy: false,
          isOffline: !isOnline,
          errorMessage: 'Unable to unlock account: $error',
        ),
      );
    }
  }

  Future<void> selectRememberedAccountOffline({required String userId}) async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final account = await _repository.readRememberedAccount(userId);
      if (account == null) {
        emit(
          state.copyWith(
            phase: MobileAuthPhase.signedOut,
            isBusy: false,
            isOffline: true,
            errorMessage:
                'This saved account is no longer available on this device.',
          ),
        );
        return;
      }

      final identity = await _repository.getDeviceIdentity();
      final localResult = await _localAuthentication.authenticate();
      if (localResult != AuthenticationResult.authenticated) {
        emit(
          state.copyWith(
            phase: MobileAuthPhase.signedOut,
            isBusy: false,
            isOffline: true,
            errorMessage: _localAuthenticationMessage(localResult),
          ),
        );
        return;
      }

      final user = account.toMobileUser();
      await _repository.saveUser(user);

      emit(
        MobileAuthState(
          phase: MobileAuthPhase.signedIn,
          user: user,
          identity: identity,
          device: MobileDevice(
            id: account.deviceId.isNotEmpty
                ? account.deviceId
                : 'OFFLINE_DEVICE',
            status: 'ACTIVE',
          ),
          isOffline: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          phase: MobileAuthPhase.signedOut,
          isBusy: false,
          isOffline: true,
          errorMessage: 'Unable to authenticate offline: $error',
        ),
      );
    }
  }

  Future<void> signIn({
    required bool isOnline,
    required bool isStaff,
    required String username,
    required String password,
  }) async {
    if (state.isBusy) return;
    if (!isOnline) {
      emit(
        state.copyWith(
          phase: MobileAuthPhase.signedOut,
          isOffline: true,
          errorMessage: 'Internet connection is required for first-time sign in. Once your account and device are securely registered, offline access is available.',
        ),
      );
      return;
    }

    emit(state.copyWith(isBusy: true, clearError: true));
    _pendingPassword = password;
    _pendingUsername = username;
    _pendingIsStaff = isStaff;
    try {
      final identity = await _repository.getDeviceIdentity();
      final user = await _repository.signIn(
        isStaff: isStaff,
        username: username,
        password: password,
        installationId: identity.installationId,
      );
      final result = await _repository.checkDevice(identity.installationId);
      if (result.enrolled) {
        final device = result.device!;
        final localResult = await _localAuthentication.authenticate();
        if (localResult != AuthenticationResult.authenticated) {
          _clearPendingCredentials();
          await _repository.clearSession();
          emit(
            state.copyWith(
              phase: MobileAuthPhase.signedOut,
              isBusy: false,
              isOffline: false,
              errorMessage: 'Authentication failed. Device authentication was not completed. You have not been signed in.',
            ),
          );
          return;
        }
        await _repository.saveUser(user);
        if (_pendingPassword != null) {
          await _repository.saveRememberedAccount(
            user: user,
            password: _pendingPassword!,
            deviceId: device.id,
            installationId: identity.installationId,
            authUsername: _pendingUsername ?? '',
            isStaff: _pendingIsStaff ?? true,
          );
        }
        _clearPendingCredentials();
        emit(
          MobileAuthState(
            phase: MobileAuthPhase.signedIn,
            user: user,
            identity: identity,
            device: device,
          ),
        );
      } else {
        emit(
          MobileAuthState(
            phase: MobileAuthPhase.enrollmentRequired,
            user: user,
            identity: identity,
          ),
        );
      }
    } on MobileApiException catch (error) {
      _clearPendingCredentials();
      emit(
        state.copyWith(
          phase: MobileAuthPhase.signedOut,
          isBusy: false,
          isOffline: false,
          errorMessage: error.message,
        ),
      );
    } on SocketException catch (_) {
      _clearPendingCredentials();
      emit(
        state.copyWith(
          phase: MobileAuthPhase.signedOut,
          isBusy: false,
          isOffline: true,
          errorMessage:
              'KMFRI sign in could not be reached. Check your connection.',
        ),
      );
    } on HttpException catch (_) {
      _clearPendingCredentials();
      emit(
        state.copyWith(
          phase: MobileAuthPhase.signedOut,
          isBusy: false,
          isOffline: true,
          errorMessage:
              'KMFRI sign in could not be reached. Check your connection.',
        ),
      );
    } on TimeoutException catch (_) {
      _clearPendingCredentials();
      emit(
        state.copyWith(
          phase: MobileAuthPhase.signedOut,
          isBusy: false,
          isOffline: true,
          errorMessage:
              'KMFRI sign in timed out. Check your connection and retry.',
        ),
      );
    } catch (error) {
      _clearPendingCredentials();
      emit(
        state.copyWith(
          phase: MobileAuthPhase.signedOut,
          isBusy: false,
          errorMessage: 'Unable to sign in: $error',
        ),
      );
    }
  }

  Future<void> completeOnboarding() async {
    await _repository.setOnboardingCompleted();
    if (_postOnboardingState != null) {
      emit(_postOnboardingState!);
    } else {
      final stateVal = await _evaluateSession(isOnline: true);
      emit(stateVal);
    }
  }

  void showOnboarding() {
    emit(
      MobileAuthState(
        phase: MobileAuthPhase.onboardingRequired,
        identity: state.identity,
        isOffline: state.isOffline,
      ),
    );
  }

  Future<void> enrollDevice() async {
    final user = state.user;
    final identity = state.identity;
    if (state.isBusy ||
        user == null ||
        identity == null ||
        state.phase != MobileAuthPhase.enrollmentRequired) {
      return;
    }

    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final device = await _repository.enrollDevice(identity);
      await _repository.saveUser(user);
      if (_pendingPassword != null) {
        await _repository.saveRememberedAccount(
          user: user,
          password: _pendingPassword!,
          deviceId: device.id,
          installationId: identity.installationId,
          authUsername: _pendingUsername ?? '',
          isStaff: _pendingIsStaff ?? true,
        );
      }
      _clearPendingCredentials();
      emit(
        MobileAuthState(
          phase: MobileAuthPhase.signedIn,
          user: user,
          identity: identity,
          device: device,
        ),
      );
    } on MobileApiException catch (error) {
      emit(state.copyWith(isBusy: false, errorMessage: error.message));
    } catch (error) {
      emit(
        state.copyWith(
          isBusy: false,
          errorMessage: 'Device enrollment failed: $error',
        ),
      );
    }
  }

  Future<void> cancelEnrollment() async {
    _clearPendingCredentials();
    String? signOutError;
    try {
      await _repository.signOut();
    } catch (error) {
      signOutError =
          'The server sign-out could not be confirmed. The local session was cleared. ($error)';
      await _repository.clearSession();
    }
    emit(
      MobileAuthState(
        phase: MobileAuthPhase.signedOut,
        identity: state.identity,
        errorMessage: signOutError,
      ),
    );
  }

  Future<void> signOut({required bool isOnline}) async {
    final identity = state.identity;
    _clearPendingCredentials();
    String? signOutError;
    try {
      if (isOnline) await _repository.signOut();
    } catch (error) {
      signOutError =
          'The server sign-out could not be confirmed. The local session was cleared. ($error)';
    } finally {
      await _repository.clearSession();
    }
    emit(
      MobileAuthState(
        phase: MobileAuthPhase.signedOut,
        identity: identity,
        isOffline: !isOnline,
        errorMessage: signOutError,
      ),
    );
  }

  Future<MobileAuthState?> _getOfflineSessionState() async {
    final user = await _repository.readUser();
    final deviceId = await _repository.readDeviceId();
    final identity = await _repository.getDeviceIdentity();
    if (user == null || deviceId == null) {
      return null;
    }

    final localResult = await _localAuthentication.authenticate();
    if (localResult != AuthenticationResult.authenticated) {
      return MobileAuthState(
        phase: MobileAuthPhase.signedOut,
        identity: identity,
        isOffline: true,
        errorMessage: _localAuthenticationMessage(localResult),
      );
    }

    return MobileAuthState(
      phase: MobileAuthPhase.signedIn,
      user: user,
      identity: identity,
      device: MobileDevice(id: deviceId, status: 'ACTIVE'),
      isOffline: true,
    );
  }

  bool _canUseOfflineSession(MobileApiException error) =>
      error.statusCode == null ||
      error.statusCode! >= 500 ||
      error.statusCode == 408 ||
      error.statusCode == 429;

  void _clearPendingCredentials() {
    _pendingPassword = null;
    _pendingUsername = null;
    _pendingIsStaff = null;
  }

  String _localAuthenticationMessage(AuthenticationResult result) {
    switch (result) {
      case AuthenticationResult.unsupported:
        return 'Set up device screen lock or biometrics to access this account.';
      case AuthenticationResult.cancelled:
        return 'Local authentication was cancelled.';
      case AuthenticationResult.failed:
        return 'Local authentication failed. Try again.';
      case AuthenticationResult.authenticated:
        return '';
    }
  }
}
