import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationRequirementGate extends StatefulWidget {
  const LocationRequirementGate({super.key, required this.child});

  final Widget child;

  @override
  State<LocationRequirementGate> createState() =>
      _LocationRequirementGateState();
}

class _LocationRequirementGateState extends State<LocationRequirementGate>
    with WidgetsBindingObserver {
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  _LocationGateStatus _status = _LocationGateStatus.checking;
  String? _errorMessage;
  bool _hasReachedReady = false;
  bool _checking = false;
  bool _refreshQueued = false;
  bool _requestPermissionQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
      (serviceStatus) {
        if (serviceStatus == ServiceStatus.disabled) {
          _setStatus(_LocationGateStatus.serviceDisabled);
        }
        unawaited(_refreshLocation());
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Location service listener error: $error');
        _setStatus(
          _LocationGateStatus.error,
          'Unable to monitor device location: $error',
        );
      },
    );
    unawaited(_refreshLocation(requestPermission: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshLocation());
    }
  }

  Future<void> _refreshLocation({bool requestPermission = false}) async {
    if (!mounted) return;
    if (_checking) {
      _refreshQueued = true;
      _requestPermissionQueued |= requestPermission;
      return;
    }

    _checking = true;
    var shouldRequestPermission = requestPermission;
    do {
      _refreshQueued = false;
      shouldRequestPermission |= _requestPermissionQueued;
      _requestPermissionQueued = false;
      _setStatus(_LocationGateStatus.checking);

      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied &&
            shouldRequestPermission) {
          permission = await Geolocator.requestPermission();
        }
        shouldRequestPermission = false;

        if (permission == LocationPermission.denied) {
          _setStatus(_LocationGateStatus.permissionDenied);
        } else if (permission == LocationPermission.deniedForever) {
          _setStatus(_LocationGateStatus.permissionDeniedForever);
        } else if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          _setStatus(
            _LocationGateStatus.error,
            'The device could not determine location permission status.',
          );
        } else if (!await Geolocator.isLocationServiceEnabled()) {
          _setStatus(_LocationGateStatus.serviceDisabled);
        } else {
          _setStatus(_LocationGateStatus.ready);
        }
      } catch (error) {
        _setStatus(
          _LocationGateStatus.error,
          'Unable to check device location: $error',
        );
      }
    } while (_refreshQueued && mounted);
    _checking = false;
  }

  void _setStatus(_LocationGateStatus status, [String? errorMessage]) {
    if (!mounted) return;
    if (status == _LocationGateStatus.ready) {
      _hasReachedReady = true;
    }
    if (_status == status && _errorMessage == errorMessage) return;
    setState(() {
      _status = status;
      _errorMessage = errorMessage;
    });
  }

  Future<void> _openRequiredSettings() async {
    try {
      final opened = switch (_status) {
        _LocationGateStatus.serviceDisabled =>
          await Geolocator.openLocationSettings(),
        _LocationGateStatus.permissionDeniedForever =>
          await Geolocator.openAppSettings(),
        _ => false,
      };
      if (!opened) {
        throw StateError('Unable to open device settings.');
      }
    } catch (error) {
      _setStatus(
        _LocationGateStatus.error,
        'Could not open device settings: $error',
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_serviceStatusSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _status == _LocationGateStatus.ready;
    if (!_hasReachedReady) {
      return isReady
          ? widget.child
          : _LocationRequirementScreen(
              status: _status,
              errorMessage: _errorMessage,
              onRetry: () => _refreshLocation(requestPermission: true),
              onOpenSettings: _openRequiredSettings,
            );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: !isReady,
          child: TickerMode(enabled: isReady, child: widget.child),
        ),
        if (!isReady)
          _LocationRequirementScreen(
            status: _status,
            errorMessage: _errorMessage,
            onRetry: () => _refreshLocation(requestPermission: true),
            onOpenSettings: _openRequiredSettings,
          ),
      ],
    );
  }
}

enum _LocationGateStatus {
  checking,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  ready,
  error,
}

class _LocationRequirementScreen extends StatelessWidget {
  const _LocationRequirementScreen({
    required this.status,
    required this.errorMessage,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final _LocationGateStatus status;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final isChecking = status == _LocationGateStatus.checking;
    final needsSettings =
        status == _LocationGateStatus.serviceDisabled ||
        status == _LocationGateStatus.permissionDeniedForever;
    final title = switch (status) {
      _LocationGateStatus.permissionDenied => 'Location permission needed',
      _LocationGateStatus.permissionDeniedForever =>
        'Allow location in Settings',
      _LocationGateStatus.serviceDisabled => 'Turn on device location',
      _LocationGateStatus.error => 'Location check unavailable',
      _ => 'Checking device location',
    };
    final description = switch (status) {
      _LocationGateStatus.permissionDenied =>
        'Allow location access to continue using KMFRI Clocking.',
      _LocationGateStatus.permissionDeniedForever =>
        'Location permission is blocked. Allow it in app settings to continue.',
      _LocationGateStatus.serviceDisabled => 'Turn on your device location services. KMFRI Clocking needs location to continue.',
      _LocationGateStatus.error =>
        errorMessage ?? 'Please check your location settings and try again.',
      _ => 'KMFRI Clocking requires device location to continue.',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1F8),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      isChecking
                          ? Icons.location_searching_rounded
                          : Icons.location_off_rounded,
                      size: 42,
                      color: const Color(0xFF005B96),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF0A3D62),
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF526575),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (isChecking)
                    const CircularProgressIndicator(color: Color(0xFF005B96))
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: needsSettings ? onOpenSettings : onRetry,
                        icon: Icon(
                          needsSettings
                              ? Icons.settings_rounded
                              : Icons.refresh_rounded,
                        ),
                        label: Text(
                          needsSettings
                              ? 'Open ${status == _LocationGateStatus.serviceDisabled ? 'location' : 'app'} settings'
                              : status == _LocationGateStatus.error
                              ? 'Try again'
                              : 'Allow location access',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF005B96),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (needsSettings ||
                        status == _LocationGateStatus.error) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Check again'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
