import 'package:flutter/material.dart';

import '../model/connectivity_status.dart';

class CheckingScreen extends StatelessWidget {
  const CheckingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFD),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF005B96)),
            SizedBox(height: 20),
            Text(
              'Connecting...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A3D62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckingSnackbar extends StatelessWidget {
  const CheckingSnackbar({
    super.key,
    required this.isChecking,
    required this.status,
  });

  final bool isChecking;
  final ConnectivityStatus status;

  @override
  Widget build(BuildContext context) {
    final isOnline = status == ConnectivityStatus.online;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0A3D62),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A3D62),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              if (isChecking) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Checking connection...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ] else ...[
                Icon(
                  isOnline
                      ? Icons.check_circle_rounded
                      : Icons.wifi_off_rounded,
                  color: isOnline
                      ? const Color(0xFF48C9B0)
                      : const Color(0xFFFFB74D),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    isOnline ? 'Connected to KMFRI' : 'Offline mode active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

