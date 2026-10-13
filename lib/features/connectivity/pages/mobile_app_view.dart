import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../authentication/cubit/mobile_auth_cubit.dart';
import '../../authentication/cubit/mobile_auth_state.dart';
import '../../authentication/pages/clocking_dashboard_screen.dart';
import '../../authentication/pages/device_enrollment_screen.dart';
import '../../authentication/pages/mobile_sign_in_screen.dart';
import '../../authentication/pages/onboarding_tutorial_screen.dart';

class MobileAppView extends StatefulWidget {
  const MobileAppView({super.key, required this.isOnline});

  final bool isOnline;

  @override
  State<MobileAppView> createState() => _MobileAppViewState();
}

class _MobileAppViewState extends State<MobileAppView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MobileAuthCubit>().initialize(isOnline: widget.isOnline);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MobileAuthCubit, MobileAuthState>(
      builder: (context, state) {
        switch (state.phase) {
          case MobileAuthPhase.initializing:
            return const _SessionLoadingScreen();
          case MobileAuthPhase.onboardingRequired:
            return OnboardingTutorialScreen(
              onGetStarted: () =>
                  context.read<MobileAuthCubit>().completeOnboarding(),
            );
          case MobileAuthPhase.signedOut:
            return MobileSignInScreen(
              isOnline: widget.isOnline,
              errorMessage: state.errorMessage,
            );
          case MobileAuthPhase.enrollmentRequired:
            return DeviceEnrollmentScreen(
              user: state.user!,
              identity: state.identity!,
              isBusy: state.isBusy,
              errorMessage: state.errorMessage,
            );
          case MobileAuthPhase.signedIn:
            return ClockingDashboardScreen(
              user: state.user!,
              device: state.device!,
              identity: state.identity!,
              isOnline: widget.isOnline,
              onSignOut: () => context.read<MobileAuthCubit>().signOut(
                isOnline: widget.isOnline,
              ),
            );
        }
      },
    );
  }
}

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFFF8FAFD),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF005B96)),
          SizedBox(height: 18),
          Text(
            'securing your session...',
            style: TextStyle(
              color: Color(0xFF0A3D62),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
