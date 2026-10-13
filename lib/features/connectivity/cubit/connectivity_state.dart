import '../model/connectivity_status.dart';

class ConnectivityState {
  const ConnectivityState({
    required this.status,
    this.isChecking = false,
    this.showSuccessBanner = false,
  });

  final ConnectivityStatus status;
  final bool isChecking;
  final bool showSuccessBanner;

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    bool? isChecking,
    bool? showSuccessBanner,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      isChecking: isChecking ?? this.isChecking,
      showSuccessBanner: showSuccessBanner ?? this.showSuccessBanner,
    );
  }
}



