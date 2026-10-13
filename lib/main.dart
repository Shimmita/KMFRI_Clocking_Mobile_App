import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'features/authentication/cubit/mobile_auth_cubit.dart';
import 'features/authentication/repository/authentication_repository.dart';
import 'features/authentication/repository/mobile_auth_repository.dart';
import 'features/authentication/service/authentication_service.dart';
import 'features/authentication/service/device_identity_service.dart';
import 'features/authentication/service/mobile_api_service.dart';
import 'features/connectivity/cubit/connectivity_cubit.dart';
import 'features/connectivity/pages/app_router.dart';
import 'features/connectivity/repository/connectivity_repository.dart';
import 'features/connectivity/service/connectivity_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KMFRIClockingApp());
}

class KMFRIClockingApp extends StatelessWidget {
  const KMFRIClockingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clocking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFD),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005B96),
        ),
      ),
      home: BlocProvider(
        create: (_) => ConnectivityCubit(
          ConnectivityRepository(ConnectivityService()),
        )..startMonitoring(),
        child: BlocProvider(
          create: (_) {
            const secureStorage = FlutterSecureStorage();
            return MobileAuthCubit(
              MobileAuthRepository(
                MobileApiService(storage: secureStorage),
                DeviceIdentityService(storage: secureStorage),
              ),
              AuthenticationRepository(AuthenticationService()),
            );
          },
          child: const AppRouter(),
        ),
      ),
    );
  }
}
