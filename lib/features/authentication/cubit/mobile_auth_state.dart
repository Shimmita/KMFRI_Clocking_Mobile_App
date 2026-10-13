import '../model/mobile_device.dart';
import '../model/mobile_device_identity.dart';
import '../model/mobile_user.dart';

enum MobileAuthPhase {
  initializing,
  onboardingRequired,
  signedOut,
  enrollmentRequired,
  signedIn,
}

class MobileAuthState {
  const MobileAuthState({
    this.phase = MobileAuthPhase.initializing,
    this.user,
    this.identity,
    this.device,
    this.isBusy = false,
    this.isOffline = false,
    this.errorMessage,
  });

  final MobileAuthPhase phase;
  final MobileUser? user;
  final MobileDeviceIdentity? identity;
  final MobileDevice? device;
  final bool isBusy;
  final bool isOffline;
  final String? errorMessage;

  MobileAuthState copyWith({
    MobileAuthPhase? phase,
    MobileUser? user,
    MobileDeviceIdentity? identity,
    MobileDevice? device,
    bool? isBusy,
    bool? isOffline,
    String? errorMessage,
    bool clearError = false,
  }) => MobileAuthState(
    phase: phase ?? this.phase,
    user: user ?? this.user,
    identity: identity ?? this.identity,
    device: device ?? this.device,
    isBusy: isBusy ?? this.isBusy,
    isOffline: isOffline ?? this.isOffline,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
