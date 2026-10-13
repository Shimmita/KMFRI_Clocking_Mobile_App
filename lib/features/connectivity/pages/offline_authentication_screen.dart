import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../authentication/cubit/authentication_cubit.dart';
import '../../authentication/cubit/authentication_state.dart';
import '../../authentication/model/authentication_result.dart';
import '../../authentication/repository/authentication_repository.dart';
import '../../authentication/service/authentication_service.dart';
import '../../clocking/pages/offline_clocking_screen.dart';

class OfflineAuthenticationScreen extends StatelessWidget {
  const OfflineAuthenticationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthenticationCubit(
        AuthenticationRepository(AuthenticationService()),
      ),
      child: BlocListener<AuthenticationCubit, AuthenticationState>(
        listenWhen: (previous, current) => previous.result != current.result,
        listener: (context, state) {
          switch (state.result) {
            case AuthenticationResult.authenticated:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const OfflineClockingScreen(),
                ),
              );
            case AuthenticationResult.unsupported:
              _showMessage(
                context,
                'This device does not support secure authentication.',
              );
            case AuthenticationResult.cancelled:
              _showMessage(context, 'Authentication was cancelled.');
            case AuthenticationResult.failed:
              _showMessage(context, 'Authentication failed. Please try again.');
            case null:
              break;
          }
        },
        child: const _OfflineAuthenticationView(),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OfflineAuthenticationView extends StatelessWidget {
  const _OfflineAuthenticationView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A3D62),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'KMFRI CLOCKING',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A3D62),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 18,
                          color: Color(0xFFB26A00),
                        ),
                        SizedBox(width: 7),
                        Text(
                          'YOU ARE USING OFFLINE MODE',
                          style: TextStyle(
                            color: Color(0xFF8A5700),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'No connection to KMFRI',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You can still clock in or out. Your records will be '
                    'synchronized when the connection returns.',
                    style: TextStyle(color: Color(0xFF6B7280), height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _feature(
                    Icons.fingerprint_rounded,
                    'Device authentication',
                    'Use your fingerprint, face or device PIN.',
                  ),
                  const SizedBox(height: 12),
                  _feature(
                    Icons.sync_rounded,
                    'Automatic synchronization',
                    'Records will sync when online.',
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child:
                        BlocBuilder<AuthenticationCubit, AuthenticationState>(
                          builder: (context, state) => FilledButton.icon(
                            onPressed: state.isAuthenticating
                                ? null
                                : context
                                      .read<AuthenticationCubit>()
                                      .authenticate,
                            icon: state.isAuthenticating
                                ? const SizedBox(
                                    width: 21,
                                    height: 21,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.fingerprint_rounded),
                            label: Text(
                              state.isAuthenticating
                                  ? 'AUTHENTICATING...'
                                  : 'AUTHENTICATE TO CLOCK',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF005B96),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF005B96)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
