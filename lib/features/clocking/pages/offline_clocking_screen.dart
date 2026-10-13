import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/offline_clocking_cubit.dart';
import '../cubit/offline_clocking_state.dart';
import '../model/clocking_record.dart';
import '../repository/offline_clocking_repository.dart';

class OfflineClockingScreen extends StatelessWidget {
  const OfflineClockingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OfflineClockingCubit(OfflineClockingRepository()),
      child: const _OfflineClockingView(),
    );
  }
}

class _OfflineClockingView extends StatelessWidget {
  const _OfflineClockingView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineClockingCubit, OfflineClockingState>(
      listenWhen: (previous, current) =>
          previous.lastActionMessage != current.lastActionMessage,
      listener: (context, state) {
        if (state.lastActionMessage == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(state.lastActionMessage!),
              ],
            ),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFD),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A3D62),
          foregroundColor: Colors.white,
          title: const Text(
            'KMFRI Clocking',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<OfflineClockingCubit, OfflineClockingState>(
            builder: (context, state) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _offlineBanner(),
                  const SizedBox(height: 25),
                  const Text(
                    'Offline Clocking',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A3D62),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Authenticated device',
                    style: TextStyle(
                      color: Color(0xFF48C9B0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _statusCard(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: FilledButton.icon(
                      onPressed: state.isClockedIn
                          ? context.read<OfflineClockingCubit>().clockOut
                          : context.read<OfflineClockingCubit>().clockIn,
                      icon: Icon(
                        state.isClockedIn
                            ? Icons.logout_rounded
                            : Icons.login_rounded,
                      ),
                      label: Text(
                        state.isClockedIn ? 'CLOCK OUT' : 'CLOCK IN',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: state.isClockedIn
                            ? const Color(0xFFFF6F61)
                            : const Color(0xFF005B96),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Recent Clocking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A3D62),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.records.isEmpty)
                    _emptyState()
                  else
                    ...state.records.map(_recordCard),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _offlineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A3D62), Color(0xFF005B96)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your records will synchronize when the connection returns.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Color(0xFF48C9B0)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Device authentication',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'VERIFIED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16836D),
                ),
              ),
            ],
          ),
          Divider(height: 28),
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: Color(0xFF005B96)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Clocking station',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
              Text('KMFRI', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: const Column(
        children: [
          Icon(Icons.access_time_rounded, size: 38, color: Color(0xFF87CEEB)),
          SizedBox(height: 10),
          Text(
            'No offline clocking yet',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 5),
          Text(
            'Your clocking records will appear here.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _recordCard(ClockingRecord record) {
    final time = record.time;
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: Color(0xFF005B96),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.type,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$hour:$minute $period',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PENDING SYNC',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8A5700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
