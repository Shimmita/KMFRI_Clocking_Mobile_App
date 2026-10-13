import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/mobile_auth_cubit.dart';
import '../model/mobile_device_identity.dart';
import '../model/mobile_user.dart';

class DeviceEnrollmentScreen extends StatelessWidget {
  const DeviceEnrollmentScreen({
    super.key,
    required this.user,
    required this.identity,
    required this.isBusy,
    this.errorMessage,
  });

  final MobileUser user;
  final MobileDeviceIdentity identity;
  final bool isBusy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFD),
        foregroundColor: const Color(0xFF0A3D62),
        title: const Text('Device security'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF3FA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phonelink_lock_rounded,
                      color: Color(0xFF005B96),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 23),
                  const Text(
                    'Secure This Device',
                    style: TextStyle(
                      color: Color(0xFF0A3D62),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This phone will be securely linked to your KMFRI Clocking account. If you replace or lose this phone, an authorized administrator must release the device before another can be enrolled.',
                    style: TextStyle(
                      color: Color(0xFF596579),
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _detailCard(
                    icon: Icons.person_outline_rounded,
                    label: 'Account',
                    value: user.name.isEmpty ? user.email : user.name,
                  ),
                  const SizedBox(height: 10),
                  _detailCard(
                    icon: Icons.smartphone_rounded,
                    label: 'Device',
                    value: identity.deviceName,
                  ),
                  const SizedBox(height: 10),
                  _detailCard(
                    icon: Icons.security_rounded,
                    label: 'Operating system',
                    value: '${identity.deviceOS} ${identity.deviceOSVersion}',
                  ),
                  const SizedBox(height: 24),
                  if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBE9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFF9F3027),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  FilledButton.icon(
                    onPressed: isBusy
                        ? null
                        : () => context.read<MobileAuthCubit>().enrollDevice(),
                    icon: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.verified_user_outlined),
                    label: Text(isBusy ? 'SECURING DEVICE...' : 'ENROLL THIS DEVICE'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF005B96),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => context
                              .read<MobileAuthCubit>()
                              .cancelEnrollment(),
                    child: const Text('Cancel and return to sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String label,
    required String value,
  }) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE8EEF7)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF005B96)),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0A3D62),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
