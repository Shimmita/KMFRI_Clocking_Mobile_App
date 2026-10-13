import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String kmfriUrl = 'https://clocking.kmfri.go.ke/';
const String _sectigoRootAssetPath =
    'android/app/src/main/res/raw/sectigo_public_server_authentication_root_r46.pem';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Future<bool> isKMFRIReachable() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none) ||
        connectivityResults.isEmpty) {
      return false;
    }

    final rootCertificate = await rootBundle.load(_sectigoRootAssetPath);
    final securityContext = SecurityContext(withTrustedRoots: true)
      ..setTrustedCertificatesBytes(
        rootCertificate.buffer.asUint8List(
          rootCertificate.offsetInBytes,
          rootCertificate.lengthInBytes,
        ),
      );
    final client = HttpClient(context: securityContext)
      ..connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.getUrl(Uri.parse(kmfriUrl));
      final response = await request.close();
      await response.drain();
      return response.statusCode >= 200 && response.statusCode < 500;
    } on SocketException catch (e) {
      debugPrint('KMFRI Socket Error: $e');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('KMFRI Timeout: $e');
      return false;
    } catch (error) {
      debugPrint('KMFRI reachability error: $error');
      return false;
    } finally {
      client.close(force: true);
    }
  }
}

