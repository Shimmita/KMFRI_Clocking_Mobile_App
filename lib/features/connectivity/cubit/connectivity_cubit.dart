import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/connectivity_status.dart';
import '../repository/connectivity_repository.dart';
import 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit(this._repository)
    : super(
        const ConnectivityState(
          status: ConnectivityStatus.checking,
          isChecking: true,
        ),
      );

  final ConnectivityRepository _repository;
  Timer? _timer;
  Timer? _bannerTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _checking = false;
  bool _checkPending = false;

  void startMonitoring() {
    if (_timer != null) return;

    _connectivitySubscription = _repository.onConnectivityChanged.listen(
      (_) => checkConnection(queueIfChecking: true),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Connectivity listener error: $error');
      },
    );
    checkConnection();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => checkConnection(),
    );
  }

  Future<void> checkConnection({bool queueIfChecking = false}) async {
    if (isClosed) return;
    if (_checking) {
      if (queueIfChecking) _checkPending = true;
      return;
    }

    _checking = true;
    emit(state.copyWith(isChecking: true, showSuccessBanner: false));

    try {
      final reachable = await _repository.isKMFRIReachable();
      if (!isClosed) {
        final newStatus = reachable
            ? ConnectivityStatus.online
            : ConnectivityStatus.offline;

        emit(
          ConnectivityState(
            status: newStatus,
            isChecking: false,
            showSuccessBanner: true,
          ),
        );

        _bannerTimer?.cancel();
        _bannerTimer = Timer(const Duration(seconds: 3), () {
          if (!isClosed) {
            emit(state.copyWith(showSuccessBanner: false));
          }
        });
      }
    } finally {
      _checking = false;
      if (_checkPending && !isClosed) {
        _checkPending = false;
        unawaited(checkConnection());
      }
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _bannerTimer?.cancel();
    await _connectivitySubscription?.cancel();
    await super.close();
  }
}
