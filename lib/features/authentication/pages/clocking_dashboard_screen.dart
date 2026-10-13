import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../clocking/cubit/mobile_clocking_cubit.dart';
import '../../clocking/cubit/mobile_clocking_state.dart';
import '../../clocking/model/attendance_history_record.dart';
import '../../clocking/model/clocking_record.dart';
import '../../clocking/repository/mobile_clocking_repository.dart';
import '../../../shared/components/kmfri_navigation_drawer.dart';
import '../model/mobile_device.dart';
import '../model/mobile_device_identity.dart';
import '../model/mobile_user.dart';
import '../service/mobile_api_service.dart';
import 'user_profile_screen.dart';

class ClockingDashboardScreen extends StatefulWidget {
  const ClockingDashboardScreen({
    super.key,
    required this.user,
    required this.device,
    required this.identity,
    required this.isOnline,
    required this.onSignOut,
  });

  final MobileUser user;
  final MobileDevice device;
  final MobileDeviceIdentity identity;
  final bool isOnline;
  final VoidCallback onSignOut;

  @override
  State<ClockingDashboardScreen> createState() =>
      _ClockingDashboardScreenState();
}

class _ClockingDashboardScreenState extends State<ClockingDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MobileClockingCubit(
        MobileClockingRepository(MobileApiService()),
        widget.user,
        widget.device,
        widget.identity,
      )..initialize(isOnline: widget.isOnline),
      child: _DashboardView(
        user: widget.user,
        device: widget.device,
        identity: widget.identity,
        isOnline: widget.isOnline,
        onSignOut: widget.onSignOut,
      ),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView({
    required this.user,
    required this.device,
    required this.identity,
    required this.isOnline,
    required this.onSignOut,
  });

  final MobileUser user;
  final MobileDevice device;
  final MobileDeviceIdentity identity;
  final bool isOnline;
  final VoidCallback onSignOut;

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  bool _syncAuthenticationDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<MobileClockingCubit>()
            .refreshLocation(promptIfDisabled: true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      context.read<MobileClockingCubit>().updateConnectivity(widget.isOnline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D62),
        foregroundColor: Colors.white,
        elevation: 2,
        scrolledUnderElevation: 2,
        toolbarHeight: 65,
        title: Row(
          children: [
            // Kenya Coat of Arms Logo
            Image.asset(
              'assets/images/gov_logo.png',
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            // KMFRI Logo inside clean white card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/kmfri_logo.png',
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            // Title & Subtitle
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KMFRI CLOCKING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ATTENDANCE SYSTEM',
                    style: TextStyle(
                      color: Color(0xFF87CEEB),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => UserProfileScreen(
                    user: widget.user,
                    onSignOut: widget.onSignOut,
                  ),
                ),
              ),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF005B96), Color(0xFF16856B)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.user.name.isNotEmpty
                      ? widget.user.name
                            .trim()
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join()
                            .toUpperCase()
                      : 'KM',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: KmfriNavigationDrawer(
        user: widget.user,
        onSignOut: widget.onSignOut,
        currentIndex: 0,
      ),
      body: BlocListener<MobileClockingCubit, MobileClockingState>(
        listenWhen: (previous, current) =>
            !previous.requiresSyncAuthentication &&
            current.requiresSyncAuthentication,
        listener: (context, state) => _showSyncAuthenticationDialog(context),
        child: SafeArea(
          child: BlocBuilder<MobileClockingCubit, MobileClockingState>(
            builder: (context, state) => LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final accountActive =
                    state.isAccountActive ?? widget.user.isAccountActive;
                final isOnLeave = state.isOnLeave || widget.user.isOnLeave;
                final canShowClock =
                    accountActive != false &&
                    !isOnLeave &&
                    state.holidayStatus?.isHolidayToday != true;
                return ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 28 : 18,
                    vertical: 22,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '$greeting ${widget.user.name.isEmpty ? 'User' : widget.user.name.split(' ').first}',
                              style: const TextStyle(
                                color: Color(0xFF0A3D62),
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.user.role.isEmpty
                                  ? 'KMFRI account'
                                  : widget.user.accountType.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _networkBanner(
                              widget.isOnline,
                              state.pendingCount,
                              state.isSyncing,
                            ),
                            const SizedBox(height: 16),
                            if (accountActive == false)
                              _accessNotice(
                                icon: Icons.block_rounded,
                                title: 'Account Disabled',
                                message: 'Your account is inactive. Contact your administrator for assistance.',
                                color: const Color(0xFFB42318),
                              )
                            else if (isOnLeave)
                              _accessNotice(
                                icon: Icons.event_busy_rounded,
                                title: 'On Leave',
                                message: 'Clocking is unavailable while you are on approved leave.',
                                color: const Color(0xFF005B96),
                              )
                            else if (widget.isOnline &&
                                !state.isHolidayStatusLoaded)
                              _accessNotice(
                                icon: Icons.fact_check_outlined,
                                title: 'Checking clocking access',
                                message: 'Confirming today’s holiday and account status before enabling clocking.',
                                color: const Color(0xFF005B96),
                              )
                            else if (state.holidayStatus?.isHolidayToday ==
                                true)
                              _accessNotice(
                                icon: Icons.celebration_rounded,
                                title: 'Clocking Paused',
                                message: state.holidayStatus!.message.isNotEmpty
                                    ? state.holidayStatus!.message
                                    : '${state.holidayStatus!.name} — clocking is not required today.',
                                color: const Color(0xFF005B96),
                                badge: 'HOLIDAY',
                              )
                            else ...[
                              _clockingGuide(
                                isOnline: widget.isOnline,
                                hasLocation: state.context != null,
                                canClockOutside:
                                    state.context?.canClockOutside ?? false,
                                isDeviceTrusted: widget.device.status
                                    .toLowerCase()
                                    .contains('active'),
                                isReady: state.canClock,
                              ),
                              const SizedBox(height: 16),
                              if (wide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _attendanceCard(state),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: _clockControls(
                                        context,
                                        state,
                                        canShowClock,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _attendanceCard(state),
                                const SizedBox(height: 14),
                                _clockControls(context, state, canShowClock),
                              ],
                            ],
                            if (state.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              _messageCard(state.errorMessage!, isError: true),
                            ],
                            if (state.lastActionMessage != null) ...[
                              const SizedBox(height: 10),
                              _messageCard(state.lastActionMessage!),
                            ],
                            if (state.pendingCount > 0 && widget.isOnline) ...[
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: state.isSyncing
                                    ? null
                                    : () => context
                                          .read<MobileClockingCubit>()
                                          .synchronizePending(
                                            refreshContext: true,
                                          ),
                                icon: state.isSyncing
                                    ? const SizedBox(
                                        width: 17,
                                        height: 17,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.sync_rounded),
                                label: Text(
                                  state.isSyncing
                                      ? 'SYNCHRONIZING...'
                                      : 'RETRY SYNC (${state.pendingCount})',
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            _activitySection(state.history),
                            if (state.records.any(
                              (record) => record.syncStatus != 'synced',
                            )) ...[
                              const SizedBox(height: 22),
                              _pendingActivitySection(state.records),
                            ],
                            const SizedBox(height: 22),
                            _deviceCard(widget.device, widget.identity),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _accessNotice({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    String? badge,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      border: Border.all(color: color.withValues(alpha: 0.2)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (badge != null) _statusChip(badge, color: color),
                ],
              ),
              const SizedBox(height: 5),
              Text(message, style: TextStyle(color: color, height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _clockingGuide({
    required bool isOnline,
    required bool hasLocation,
    required bool canClockOutside,
    required bool isDeviceTrusted,
    required bool isReady,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDDECEB)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WELCOME — HERE IS YOUR CLOCKING GUIDE',
          style: TextStyle(
            color: Color(0xFF0A3D62),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.35,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _guideStep('1', 'Confirm your location'),
            _guideStep('2', 'Use your assigned station'),
            _guideStep('3', 'Verify this trusted device'),
            _guideStep('4', 'Clock in or clock out'),
          ],
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            _readinessChip(
              'LOCATION',
              isReady: hasLocation,
              icon: Icons.location_on_rounded,
            ),
            _readinessChip(
              'DEVICE',
              isReady: isDeviceTrusted,
              icon: Icons.verified_user_rounded,
            ),
            _readinessChip(
              isOnline ? 'CONNECTED' : 'OFFLINE READY',
              isReady: isReady || !isOnline,
              icon: isOnline ? Icons.cloud_done_rounded : Icons.cloud_off,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _guideStep(String number, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 25,
        height: 25,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFFE8F6F2),
          shape: BoxShape.circle,
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: Color(0xFF16856B),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF344054),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _readinessChip(
    String label, {
    required bool isReady,
    required IconData icon,
  }) {
    final color = isReady ? const Color(0xFF16856B) : const Color(0xFFB26A00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, {required Color color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    ),
  );

  Widget _networkBanner(
    bool isOnline,
    int pending,
    bool isSyncing,
  ) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: isOnline ? const Color(0xFFE8F6F2) : const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(
          isSyncing
              ? Icons.sync_rounded
              : isOnline
              ? Icons.cloud_done_outlined
              : Icons.cloud_off_outlined,
          color: isOnline ? const Color(0xFF16856B) : const Color(0xFFB26A00),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            isSyncing
                ? 'Synchronizing attendance...'
                : isOnline
                ? pending > 0
                      ? '$pending record${pending == 1 ? '' : 's'} waiting to sync'
                      : 'Connected — all attendance synchronized'
                : pending > 0
                ? 'Offline — $pending record${pending == 1 ? '' : 's'} saved securely'
                : 'Offline Mode Activated',
            style: TextStyle(
              color: isOnline
                  ? const Color(0xFF176B59)
                  : const Color(0xFF8A5700),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _attendanceCard(MobileClockingState state) {
    final action = state.nextAction;
    final isClockedIn = action == 'clock_out';
    final context = state.context;
    final canClockOutside =
        widget.user.canClockOutside || (context?.canClockOutside == true);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A3D62), Color(0xFF005B96)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220A3D62),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TODAY'S ATTENDANCE",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              if (canClockOutside)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.near_me_rounded,
                            color: Color(0xFF00E5FF),
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'OUTSIDE PERMITTED',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.user.outsideClockingReason.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFB400).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFFFFB400).withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          widget.user.outsideClockingReason,
                          style: const TextStyle(
                            color: Color(0xFFFFB400),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Icon(
                state.isLoading
                    ? Icons.hourglass_top_rounded
                    : isClockedIn
                    ? Icons.login_rounded
                    : Icons.schedule_rounded,
                color: const Color(0xFF87CEEB),
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.isLoading
                      ? 'Loading your attendance status...'
                      : action == null
                      ? 'Attendance status needs attention.'
                      : isClockedIn
                      ? 'Currently Clocked In'
                      : 'Not Clocked In',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (context != null) ...[
            const SizedBox(height: 12),
            Text(
              context.stationName,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
          const SizedBox(height: 18),
          const _LiveClock(),
        ],
      ),
    );
  }

  Widget _clockControls(
    BuildContext context,
    MobileClockingState state,
    bool canShowClock,
  ) {
    final stationName = state.context?.stationName ?? 'Assigned station';
    final isOutsideBlocked = state.context != null && !state.canProceedWithLocation;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF005B96),
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  stationName,
                  style: const TextStyle(
                    color: Color(0xFF0A3D62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusChip(
                state.context == null ? 'LOADING' : 'STATION',
                color: const Color(0xFF005B96),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.fingerprint_rounded,
                color: Color(0xFF16856B),
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  widget.device.status.toLowerCase().contains('active')
                      ? 'Trusted device verified'
                      : 'Device verification required',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          if (isOutsideBlocked) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_off_rounded,
                        color: Color(0xFFB26A00),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Outside Station Premises',
                          style: TextStyle(
                            color: Color(0xFF8A5700),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You are ${state.distanceMeters ?? 0}m away from $stationName. Clocking is blocked outside station premises unless authorized.',
                    style: const TextStyle(
                      color: Color(0xFF8A5700),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .read<MobileClockingCubit>()
                        .refreshLocation(promptIfDisabled: true),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'RE-CHECK LOCATION',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8A5700),
                      side: const BorderSide(color: Color(0xFFFFB74D)),
                      minimumSize: const Size.fromHeight(38),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _clockButton(context, state, canShowClock),
          ],
          if (state.isOnline && !state.isHolidayStatusLoaded) ...[
            const SizedBox(height: 9),
            const Text(
              'Verifying clocking eligibility…',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _clockButton(
    BuildContext context,
    MobileClockingState state,
    bool canShowClock,
  ) {
    final action = state.nextAction;
    final canClock = state.canClock && canShowClock;
    final isClockOut = action == 'clock_out';
    return SizedBox(
      height: 62,
      child: FilledButton.icon(
        onPressed: canClock
            ? () => context.read<MobileClockingCubit>().clock()
            : null,
        icon: state.isClocking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const _AnimatedFingerprintIcon(),
        label: Text(
          state.isClocking
              ? 'PROCESSING CLOCKING...'
              : isClockOut
              ? 'CLOCK OUT'
              : 'CLOCK IN',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF005B96),
          disabledBackgroundColor: const Color(0xFF9CA3AF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _deviceCard(MobileDevice device, MobileDeviceIdentity identity) =>
      Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EEF7)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F6F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF16856B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Device security',
                    style: TextStyle(
                      color: Color(0xFF0A3D62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${identity.deviceName} · ${device.status.toLowerCase()}',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _activitySection(List<AttendanceHistoryRecord> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Attendance',
          style: TextStyle(
            color: Color(0xFF0A3D62),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'LAST 7 DAYS',
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 11),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EEF7)),
          ),
          child: records.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Your clocking activity will appear here.',
                    style: TextStyle(color: Color(0xFF667085)),
                  ),
                )
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Date',
                              style: TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Clock In',
                              style: TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Clock Out',
                              style: TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 16, color: Color(0xFFE8EEF7)),
                    ...records.map(
                      (record) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                _formatDate(record.date),
                                style: const TextStyle(
                                  color: Color(0xFF344054),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                record.clockInLabel,
                                style: const TextStyle(
                                  color: Color(0xFF16856B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                record.clockOutLabel,
                                style: const TextStyle(
                                  color: Color(0xFFB26A00),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _pendingActivitySection(List<ClockingRecord> records) {
    final pendingRecords = records
        .where((record) => record.syncStatus != 'synced')
        .toList()
        .reversed
        .take(5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'On-device clocking records',
          style: TextStyle(
            color: Color(0xFF0A3D62),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...pendingRecords.map(_activityCard),
      ],
    );
  }

  Widget _activityCard(ClockingRecord record) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: record.syncStatus == 'rejected'
          ? () => _showRecordReviewDialog(record)
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EEF7)),
        ),
        child: Row(
          children: [
            Icon(
              record.action == 'clock_in'
                  ? Icons.login_rounded
                  : Icons.logout_rounded,
              color: const Color(0xFF005B96),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.type,
                    style: const TextStyle(
                      color: Color(0xFF0A3D62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${record.station} · ${_formatTime(record.time)}',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _syncStatus(record.syncStatus),
          ],
        ),
      ),
    ),
  );

  Future<void> _showRecordReviewDialog(ClockingRecord record) async {
    final cubit = context.read<MobileClockingCubit>();
    final retry = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Attendance needs review'),
        content: Text(
          record.syncMessage?.trim().isNotEmpty == true
              ? record.syncMessage!.trim()
              : 'This attendance record was not accepted by the server. You can retry sending the original event.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CLOSE'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.sync_rounded),
            label: Text(widget.isOnline ? 'RETRY SYNC' : 'RETRY WHEN ONLINE'),
          ),
        ],
      ),
    );
    if (retry == true && mounted) {
      await cubit.retrySynchronization(record.localRecordId);
    }
  }

  Widget _syncStatus(String status) {
    final color = status == 'synced'
        ? const Color(0xFF16856B)
        : status == 'rejected'
        ? const Color(0xFFB42318)
        : const Color(0xFFB26A00);
    final label = status == 'synced'
        ? 'Synced'
        : status == 'rejected'
        ? 'Review'
        : 'Pending';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          status == 'synced'
              ? Icons.check_circle_outline
              : status == 'rejected'
              ? Icons.error_outline
              : Icons.sync_rounded,
          color: color,
          size: 15,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _messageCard(String message, {bool isError = false}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isError ? const Color(0xFFFFEBE9) : const Color(0xFFE8F6F2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: isError ? const Color(0xFF9F3027) : const Color(0xFF176B59),
        fontSize: 13,
      ),
    ),
  );

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  Future<void> _showSyncAuthenticationDialog(BuildContext context) async {
    if (_syncAuthenticationDialogOpen || !mounted) return;
    _syncAuthenticationDialogOpen = true;
    final passwordController = TextEditingController();
    final cubit = context.read<MobileClockingCubit>();
    var submitting = false;
    String? errorMessage;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> authenticate() async {
              if (passwordController.text.isEmpty) {
                setDialogState(() => errorMessage = 'Enter your password.');
                return;
              }
              setDialogState(() {
                submitting = true;
                errorMessage = null;
              });
              final error = await cubit.authenticateAndSynchronize(
                passwordController.text,
              );
              if (!dialogContext.mounted) return;
              if (error == null) {
                Navigator.of(dialogContext).pop();
              } else {
                setDialogState(() {
                  submitting = false;
                  errorMessage = error;
                });
              }
            }

            final accountIdentifier = widget.user.accountType == 'Employee'
                ? widget.user.employeeId
                : widget.user.email;
            return AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Authentication required'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your saved offline attendance records need to be synchronized. Verify your ${widget.user.accountType} account password to continue.',
                  ),
                  if (accountIdentifier.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Account: $accountIdentifier',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    autofocus: true,
                    enabled: !submitting,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => authenticate(),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () {
                          FocusScope.of(dialogContext).unfocus();
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('NOT NOW'),
                ),
                FilledButton(
                  onPressed: submitting ? null : authenticate,
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('VERIFY & SYNC'),
                ),
              ],
            );
          },
        ),
      );
     } finally {
      passwordController.dispose();
      _syncAuthenticationDialogOpen = false;
      if (mounted) cubit.dismissSyncAuthenticationPrompt();
    }
  }
}

class _AnimatedFingerprintIcon extends StatefulWidget {
  const _AnimatedFingerprintIcon();

  @override
  State<_AnimatedFingerprintIcon> createState() =>
      __AnimatedFingerprintIconState();
}

class __AnimatedFingerprintIconState extends State<_AnimatedFingerprintIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: const Icon(
              Icons.fingerprint_rounded,
              size: 26,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    final day = _now.day.toString().padLeft(2, '0');
    final month = _now.month.toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$hour:$minute:$second ${_now.hour >= 12 ? 'PM' : 'AM'}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$day/$month/${_now.year}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
