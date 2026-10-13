import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/connectivity_cubit.dart';
import '../cubit/connectivity_state.dart';
import '../model/connectivity_status.dart';
import 'checking_screen.dart';
import 'location_requirement_gate.dart';
import 'mobile_app_view.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return LocationRequirementGate(
      child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, state) {
          switch (state.status) {
            case ConnectivityStatus.checking:
              return const CheckingScreen();
            case ConnectivityStatus.online:
              return const MobileAppView(isOnline: true);
            case ConnectivityStatus.offline:
              return const MobileAppView(isOnline: false);
          }
        },
      ),
    );
  }
}
