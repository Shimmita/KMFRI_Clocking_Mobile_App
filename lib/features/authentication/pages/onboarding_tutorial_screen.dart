import 'package:flutter/material.dart';

/// KMFRI Clocking - First Launch Onboarding
///
/// Flow:
/// Splash -> Onboarding -> Login / Account Selection
///
/// This screen is intentionally presentation-only.
/// It does not perform real authentication, biometric verification,
/// GPS verification, synchronization, or API calls.

class OnboardingTutorialScreen extends StatefulWidget {
  const OnboardingTutorialScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  State<OnboardingTutorialScreen> createState() =>
      _OnboardingTutorialScreenState();
}

class _OnboardingTutorialScreenState extends State<OnboardingTutorialScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  late final AnimationController _contentController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const Color deepNavy = Color(0xFF0A3D62);
  static const Color oceanBlue = Color(0xFF005B96);
  static const Color marineBlue = Color(0xFF1A237E);
  static const Color aqua = Color(0xFF00E5FF);
  static const Color seafoam = Color(0xFF48C9B0);
  static const Color cloudWhite = Color(0xFFF8FAFD);
  static const Color softGray = Color(0xFFE8EEF7);
  static const Color charcoal = Color(0xFF424242);

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      title: 'Welcome to\nKMFRI Clocking',
      description:
          'A simple and secure way to record your daily attendance with KMFRI.',
      icon: Icons.access_time_rounded,
      accent: oceanBlue,
      type: _OnboardingVisual.welcome,
    ),
    _OnboardingData(
      title: 'Your attendance.\nSecurely recorded.',
      description: 'Use your authorized account and registered device to record your attendance with confidence.',
      icon: Icons.verified_user_rounded,
      accent: deepNavy,
      type: _OnboardingVisual.security,
    ),
    _OnboardingData(
      title: 'Clock in.\nEven offline.',
      description: 'No internet? Your clocking is safely saved on this device and synchronized automatically when connectivity returns.',
      icon: Icons.cloud_off_rounded,
      accent: seafoam,
      type: _OnboardingVisual.offline,
    ),
    _OnboardingData(
      title: 'First time\nsigning in?',
      description: 'Choose Staff or Intern / Attaché, enter your Staff Number or registered email and your password. Your first sign-in securely saves this account on your phone.',
      icon: Icons.login_rounded,
      accent: oceanBlue,
      type: _OnboardingVisual.firstSignIn,
    ),
    _OnboardingData(
      title: 'Secure this\ndevice once.',
      description: 'After your first successful sign-in, tap “Enroll this device” on the Device Security screen. The phone is then securely linked to your account; another phone needs administrator release before enrollment.',
      icon: Icons.phonelink_lock_rounded,
      accent: deepNavy,
      type: _OnboardingVisual.enrollment,
    ),
    _OnboardingData(
      title: 'Return to a\nsaved account.',
      description: 'On your next visit, select your existing account to continue directly—no password entry is needed. Stay connected for server access, or continue offline to use your saved account and clocking records.',
      icon: Icons.switch_account_rounded,
      accent: seafoam,
      type: _OnboardingVisual.savedAccount,
    ),
    _OnboardingData(
      title: 'Ready to\nget started?',
      description: 'Choose a saved account for quick access, or use “Use another way” to sign in with Staff Number or registered email and password.',
      icon: Icons.verified_rounded,
      accent: oceanBlue,
      type: _OnboardingVisual.ready,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: Curves.easeOutCubic,
          ),
        );

    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _animatePageContent() {
    _contentController
      ..reset()
      ..forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onGetStarted();
    }
  }

  void _skip() {
    widget.onGetStarted();
  }

  void _goToPage(int index) {
    if (index == _currentPage) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmallHeight = size.height < 700;

    return Scaffold(
      backgroundColor: cloudWhite,
      appBar: AppBar(
        backgroundColor: deepNavy,
        foregroundColor: Colors.white,
        elevation: 2,
        scrolledUnderElevation: 2,
        toolbarHeight: 65,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/gov_logo.png',
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
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
        actions: _currentPage == _pages.length - 1
            ? null
            : [
                TextButton(
                  onPressed: _skip,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });

                  _animatePageContent();
                },
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildPage(_pages[index], isSmallHeight),
                    ),
                  );
                },
              ),
            ),

            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE
  // ---------------------------------------------------------------------------

  Widget _buildPage(_OnboardingData page, bool isSmallHeight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        final visualHeight = isSmallHeight
            ? availableHeight * 0.40
            : availableHeight * 0.47;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: isSmallHeight ? 8 : 18),

                SizedBox(
                  height: visualHeight.clamp(230.0, 370.0),
                  child: _buildVisual(page),
                ),

                SizedBox(height: isSmallHeight ? 14 : 24),

                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: deepNavy,
                    fontSize: 29,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),

                const SizedBox(height: 15),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 15,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (page.type == _OnboardingVisual.firstSignIn)
                  _buildInfoPreview(const [
                    (Icons.badge_outlined, 'Staff number'),
                    (Icons.email_outlined, 'Registered email'),
                    (Icons.lock_outline_rounded, 'Password'),
                  ]),
                if (page.type == _OnboardingVisual.enrollment)
                  _buildInfoPreview(const [
                    (Icons.smartphone_rounded, 'This phone'),
                    (Icons.link_rounded, 'Secure link'),
                    (Icons.admin_panel_settings_outlined, 'Admin release'),
                  ]),
                if (page.type == _OnboardingVisual.savedAccount)
                  _buildInfoPreview(const [
                    (Icons.person_outline_rounded, 'Saved account'),
                    (Icons.cloud_done_outlined, 'Online access'),
                    (Icons.cloud_off_rounded, 'Offline access'),
                  ]),
                if (page.type == _OnboardingVisual.ready)
                  _buildAccountPreview(),

                SizedBox(height: isSmallHeight ? 10 : 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // VISUALS
  // ---------------------------------------------------------------------------

  Widget _buildVisual(_OnboardingData page) {
    switch (page.type) {
      case _OnboardingVisual.welcome:
        return _buildWelcomeVisual();

      case _OnboardingVisual.security:
        return _buildSecurityVisual();

      case _OnboardingVisual.offline:
        return _buildOfflineVisual();

      case _OnboardingVisual.firstSignIn:
      case _OnboardingVisual.enrollment:
      case _OnboardingVisual.savedAccount:
      case _OnboardingVisual.ready:
        return _buildReadyVisual();
    }
  }

  Widget _buildWelcomeVisual() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildGlow(size: 270, color: oceanBlue, opacity: 0.08),

        _buildDecorativeCircle(size: 220, color: const Color(0xFFEAF3FA)),

        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [deepNavy, oceanBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: oceanBlue.withValues(alpha: 0.25),
                blurRadius: 35,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: const Icon(
            Icons.access_time_filled_rounded,
            color: Colors.white,
            size: 76,
          ),
        ),

        Positioned(
          right: 18,
          top: 48,
          child: _floatingIcon(Icons.location_on_rounded, oceanBlue),
        ),

        Positioned(
          left: 20,
          bottom: 38,
          child: _floatingIcon(Icons.check_circle_rounded, seafoam),
        ),

        Positioned(
          right: 54,
          bottom: 20,
          child: _floatingIcon(Icons.phone_android_rounded, marineBlue),
        ),
      ],
    );
  }

  Widget _buildSecurityVisual() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildGlow(size: 290, color: deepNavy, opacity: 0.07),

        Container(
          width: 230,
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: softGray, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: deepNavy.withValues(alpha: 0.10),
                blurRadius: 35,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 18,
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: softGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Positioned(
                top: 58,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    size: 78,
                    color: oceanBlue,
                  ),
                ),
              ),

              Positioned(
                bottom: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _securityPill(Icons.verified_user_rounded, 'Secure'),
                    const SizedBox(width: 7),
                    _securityPill(Icons.phone_android_rounded, 'Device'),
                  ],
                ),
              ),
            ],
          ),
        ),

        Positioned(
          right: 22,
          top: 35,
          child: _floatingIcon(Icons.lock_rounded, deepNavy),
        ),

        Positioned(
          left: 18,
          bottom: 40,
          child: _floatingIcon(Icons.verified_rounded, seafoam),
        ),
      ],
    );
  }

  Widget _buildOfflineVisual() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildGlow(size: 290, color: seafoam, opacity: 0.09),

        // Cloud
        Positioned(
          top: 34,
          right: 45,
          child: Container(
            width: 120,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.cloud_done_rounded,
              color: seafoam,
              size: 43,
            ),
          ),
        ),

        // Phone
        Container(
          width: 185,
          height: 265,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: softGray, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: deepNavy.withValues(alpha: 0.11),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 70,
                right: 70,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: softGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Positioned(
                top: 55,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        color: Color(0xFFB26A00),
                        size: 21,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Offline',
                          style: TextStyle(
                            color: Color(0xFF8A5700),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 120,
                left: 24,
                right: 24,
                child: _offlineRecord(
                  Icons.login_rounded,
                  'Clock In',
                  'Saved securely',
                  oceanBlue,
                ),
              ),

              Positioned(
                top: 183,
                left: 24,
                right: 24,
                child: _offlineRecord(
                  Icons.sync_rounded,
                  'Sync Later',
                  'When online',
                  seafoam,
                ),
              ),
            ],
          ),
        ),

        // Sync arrow
        Positioned(
          right: 15,
          bottom: 58,
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: deepNavy,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: deepNavy.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.sync_rounded, color: aqua, size: 29),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyVisual() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildGlow(size: 290, color: oceanBlue, opacity: 0.08),

        Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [deepNavy, oceanBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: oceanBlue.withValues(alpha: 0.23),
                blurRadius: 35,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login_rounded, color: Colors.white, size: 66),
              SizedBox(height: 13),
              Text(
                'READY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: 26,
          right: 24,
          child: _floatingIcon(Icons.person_rounded, oceanBlue),
        ),

        Positioned(
          bottom: 30,
          left: 22,
          child: _floatingIcon(Icons.lock_rounded, seafoam),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SUPPORTING VISUAL COMPONENTS
  // ---------------------------------------------------------------------------

  Widget _buildGlow({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildDecorativeCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }

  Widget _floatingIcon(IconData icon, Color color) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: softGray),
        boxShadow: [
          BoxShadow(
            color: deepNavy.withValues(alpha: 0.10),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }

  Widget _securityPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: softGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: oceanBlue, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: charcoal,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _offlineRecord(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: cloudWhite,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: softGray),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: deepNavy,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF667085), fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACCOUNT FLOW PREVIEW
  // ---------------------------------------------------------------------------

  Widget _buildInfoPreview(List<(IconData, String)> items) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: softGray),
        boxShadow: [
          BoxShadow(
            color: deepNavy.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 330;
          return Wrap(
            alignment: WrapAlignment.spaceEvenly,
            runSpacing: 8,
            spacing: narrow ? 4 : 10,
            children: items
                .map(
                  (item) => SizedBox(
                    width: narrow ? (constraints.maxWidth - 16) / 3 : 112,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.$1, color: oceanBlue, size: 20),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.$2,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                            color: charcoal,
                            fontSize: 10,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildAccountPreview() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: softGray),
        boxShadow: [
          BoxShadow(
            color: deepNavy.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roleChip(Icons.badge_outlined, 'Staff'),
          _roleChip(Icons.school_outlined, 'Intern'),
          _roleChip(Icons.work_outline_rounded, 'Attaché'),
        ],
      ),
    );
  }

  Widget _roleChip(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: oceanBlue, size: 19),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: charcoal,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM CONTROLS
  // ---------------------------------------------------------------------------

  Widget _buildBottomControls() {
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
      child: Row(
        children: [
          Expanded(child: _buildPageIndicator()),

          const SizedBox(width: 18),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: deepNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 21),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLastPage ? 'Continue' : 'Next',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLastPage
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      children: List.generate(_pages.length, (index) {
        final active = index == _currentPage;

        return GestureDetector(
          onTap: () => _goToPage(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 6),
            width: active ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? oceanBlue : const Color(0xFFD0D5DD),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }),
    );
  }
}

// -----------------------------------------------------------------------------
// DATA MODEL
// -----------------------------------------------------------------------------

enum _OnboardingVisual {
  welcome,
  security,
  offline,
  firstSignIn,
  enrollment,
  savedAccount,
  ready,
}

class _OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final _OnboardingVisual type;

  const _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.type,
  });
}
