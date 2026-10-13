import 'package:connectivity_plus/connectivity_plus.dart';

import '../service/connectivity_service.dart';

class ConnectivityRepository {
  ConnectivityRepository(this._service);

  final ConnectivityService _service;

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _service.onConnectivityChanged;

  Future<bool> isKMFRIReachable() => _service.isKMFRIReachable();
}
