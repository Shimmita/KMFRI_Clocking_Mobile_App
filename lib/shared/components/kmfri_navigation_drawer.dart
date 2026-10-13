import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/authentication/cubit/mobile_auth_cubit.dart';
import '../../features/authentication/model/mobile_user.dart';
import '../../features/data_protection/pages/data_protection_screen.dart';
import '../../features/help/pages/help_and_support_screen.dart';
import '../../features/history/pages/attendance_history_screen.dart';

class KmfriNavigationDrawer extends StatelessWidget {
  const KmfriNavigationDrawer({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.currentIndex,
  });

  final MobileUser user;
  final VoidCallback onSignOut;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'KM';

    return Drawer(
      backgroundColor: const Color(0xFF072B46),
      child: SafeArea(
        child: Column(
          children: [
            // Top Profile Card (Emulating React Sidebar Header)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A3D62), Color(0xFF005B96)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF16856B),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name.isEmpty ? 'KMFRI COLLEAGUE' : user.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.department.isEmpty
                                  ? (user.station.isEmpty ? 'KMFRI RESEARCH' : user.station)
                                  : user.department.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _profileBadge(
                        user.employeeId.isEmpty ? 'N/A' : user.employeeId,
                      ),
                      _profileBadge(user.rankLabel),
                      _profileBadge(user.accountType),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Section Header: ATTENDANCE WORKSPACE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'ATTENDANCE WORKSPACE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.2),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Workspace Navigation Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _workspaceItem(
                    icon: Icons.grid_view_rounded,
                    label: 'CLOCKING DASHBOARD',
                    isSelected: currentIndex == 0,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (currentIndex != 0) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  _workspaceItem(
                    icon: Icons.history_rounded,
                    label: 'ATTENDANCE HISTORY',
                    isSelected: currentIndex == 1,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (currentIndex != 1) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AttendanceHistoryScreen(
                              user: user,
                              onSignOut: onSignOut,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Secondary Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'RESOURCES & SUPPORT',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.2),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Secondary Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _secondaryItem(
                    icon: Icons.help_outline_rounded,
                    label: 'HELP AND SUPPORT',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HelpAndSupportScreen(
                            user: user,
                            onSignOut: onSignOut,
                          ),
                        ),
                      );
                    },
                  ),
                  _secondaryItem(
                    icon: Icons.auto_stories_rounded,
                    label: 'READ APP TUTORIAL',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.read<MobileAuthCubit>().showOnboarding();
                    },
                  ),
                  _secondaryItem(
                    icon: Icons.security_rounded,
                    label: 'DATA PROTECTION',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DataProtectionScreen(
                            user: user,
                            onSignOut: onSignOut,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSignOut();
                },
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF6F61)),
                label: const Text(
                  'SIGN OUT',
                  style: TextStyle(
                    color: Color(0xFFFF6F61),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(
                    color: const Color(0xFFFF6F61).withValues(alpha: 0.4),
                  ),
                  backgroundColor:
                      const Color(0xFFFF6F61).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _workspaceItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF005B96), Color(0xFF0A3D62)],
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: Colors.white.withValues(alpha: 0.3))
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF005B96).withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 12.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E5FF),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 20),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }
}
