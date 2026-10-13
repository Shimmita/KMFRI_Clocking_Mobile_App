import 'package:flutter/material.dart';

import '../../../shared/components/kmfri_navigation_drawer.dart';
import '../../authentication/model/mobile_user.dart';

class DataProtectionScreen extends StatelessWidget {
  const DataProtectionScreen({
    super.key,
    required this.user,
    required this.onSignOut,
  });

  final MobileUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D62),
        foregroundColor: Colors.white,
        title: const Text(
          'Data Protection & Privacy',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      drawer: KmfriNavigationDrawer(
        user: user,
        onSignOut: onSignOut,
        currentIndex: 3,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'KMFRI Information Privacy Statement',
              style: TextStyle(
                color: Color(0xFF0A3D62),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Attendance Data Collection',
              content:
                  'Attendance records (including clock-in and clock-out timestamps, shift durations, and station tags) are collected solely for official timekeeping, payroll, and institutional attendance reporting at the Kenya Marine and Fisheries Research Institute (KMFRI).',
            ),
            _sectionCard(
              title: 'Location & Geofence Information',
              content:
                  'GPS location coordinates are captured at the moment of clocking to verify compliance with authorized station geofences. Location data is not tracked continuously in the background.',
            ),
            _sectionCard(
              title: 'Device Security & Enrollment',
              content:
                  'To prevent attendance fraud and proxy clocking, your account is cryptographically bound to your registered physical device ID. Biometric authentication (fingerprint/face) remains securely on your device hardware and is never transmitted to servers.',
            ),
            _sectionCard(
              title: 'Secure Synchronization',
              content:
                  'All offline attendance records are stored in encrypted local storage and transmitted over secure TLS protocols using idempotent transaction identifiers upon synchronization.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0A3D62),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF667085),
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
