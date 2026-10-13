import 'package:flutter/material.dart';

import '../../../shared/components/kmfri_navigation_drawer.dart';
import '../../clocking/repository/mobile_clocking_repository.dart';
import '../model/mobile_user.dart';
import '../service/mobile_api_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.user,
    required this.onSignOut,
  });

  final MobileUser user;
  final VoidCallback onSignOut;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final MobileClockingRepository _repository;
  late MobileUser _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _repository = MobileClockingRepository(MobileApiService());
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final profile = await _repository.refreshUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _currentUser.name.isNotEmpty
        ? _currentUser.name
            .trim()
            .split(' ')
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'KM';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D62),
        foregroundColor: Colors.white,
        title: const Text(
          'USER PROFILE',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Profile',
            onPressed: _fetchProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      drawer: KmfriNavigationDrawer(
        user: _currentUser,
        onSignOut: widget.onSignOut,
        currentIndex: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF005B96),
                          ),
                        ),
                      ),
                    ),

                  // Avatar & Header Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A3D62), Color(0xFF005B96)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A3D62).withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF16856B),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentUser.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser.email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _badge(
                              _currentUser.employeeId.isEmpty
                                  ? 'N/A'
                                  : _currentUser.employeeId,
                            ),
                            _badge(_currentUser.rankLabel),
                            _badge(_currentUser.accountType),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Detailed Attributes Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8EEF7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personnel Information',
                          style: TextStyle(
                            color: Color(0xFF0A3D62),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _detailRow('Full Name', _currentUser.name),
                        _detailRow('Email Address', _currentUser.email),
                        _detailRow(
                          'Employee ID',
                          _currentUser.employeeId.isEmpty
                              ? 'N/A'
                              : _currentUser.employeeId,
                        ),
                        _detailRow(
                          'Department',
                          _currentUser.department.isEmpty
                              ? 'KMFRI Research'
                              : _currentUser.department,
                        ),
                        _detailRow(
                          'Station / Center',
                          _currentUser.station.isEmpty
                              ? 'KMFRI'
                              : _currentUser.station,
                        ),
                        _detailRow('Access Rank', _currentUser.rankLabel),
                        _detailRow('Employment Role', _currentUser.accountType),
                        _detailRow(
                          'Account Status',
                          _currentUser.isAccountActive == false
                              ? 'Inactive'
                              : 'Active',
                          valueColor: _currentUser.isAccountActive == false
                              ? const Color(0xFFB42318)
                              : const Color(0xFF16856B),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: widget.onSignOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('SIGN OUT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F61),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF0A3D62),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
