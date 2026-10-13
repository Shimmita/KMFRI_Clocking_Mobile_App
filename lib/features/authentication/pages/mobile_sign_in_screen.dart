import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/mobile_auth_cubit.dart';
import '../cubit/mobile_auth_state.dart';
import '../model/remembered_account.dart';

class MobileSignInScreen extends StatefulWidget {
  const MobileSignInScreen({
    super.key,
    required this.isOnline,
    this.errorMessage,
  });

  final bool isOnline;
  final String? errorMessage;

  @override
  State<MobileSignInScreen> createState() => _MobileSignInScreenState();
}

class _MobileSignInScreenState extends State<MobileSignInScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Default account type: true = Staff, false = Intern/Attaché
  bool _isStaff = true;
  bool _obscurePassword = true;
  bool _useAlternativeSignIn = false;
  RememberedAccount? _selectedRememberedAccount;
  late final Future<List<RememberedAccount>> _rememberedAccountsFuture;

  @override
  void initState() {
    super.initState();
    _rememberedAccountsFuture = context
        .read<MobileAuthCubit>()
        .loadRememberedAccounts();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Connection Status Pill
                  _connectionBanner(),
                  const SizedBox(height: 20),

                  FutureBuilder<List<RememberedAccount>>(
                    future: _rememberedAccountsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(28),
                            child: CircularProgressIndicator(
                              color: Color(0xFF005B96),
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return _errorMessage(
                          'Saved accounts could not be loaded. Please try again.',
                        );
                      }

                      final accounts =
                          snapshot.data ?? const <RememberedAccount>[];
                      if (accounts.isNotEmpty && !_useAlternativeSignIn) {
                        return _rememberedAccountCard(accounts);
                      }
                      return _signInCard(
                        hasRememberedAccounts: accounts.isNotEmpty,
                      );
                    },
                  ),

                  if (widget.errorMessage != null &&
                      widget.errorMessage!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _errorMessage(widget.errorMessage!),
                  ],

                  const SizedBox(height: 20),

                  // Tutorial Replay Quick Link
                  Center(
                    child: TextButton.icon(
                      onPressed: () =>
                          context.read<MobileAuthCubit>().showOnboarding(),
                      icon: const Icon(
                        Icons.auto_stories_rounded,
                        size: 18,
                        color: Color(0xFF005B96),
                      ),
                      label: const Text(
                        'Replay App Tutorial & Purpose',
                        style: TextStyle(
                          color: Color(0xFF005B96),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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

  Widget _connectionBanner() {
    final connected = widget.isOnline;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFFE8F6F2) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: connected
              ? const Color(0xFF16856B).withValues(alpha: 0.3)
              : const Color(0xFFFFE0B2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected
                  ? const Color(0xFF16856B)
                  : const Color(0xFFB26A00),
              boxShadow: [
                BoxShadow(
                  color:
                      (connected
                              ? const Color(0xFF16856B)
                              : const Color(0xFFB26A00))
                          .withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              connected
                  ? 'ONLINE — Connected to KMFRI Server'
                  : 'OFFLINE MODE — No internet connection',
              style: TextStyle(
                color: connected
                    ? const Color(0xFF176B59)
                    : const Color(0xFF8A5700),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rememberedAccountCard(List<RememberedAccount> accounts) {
    final selectedAccount = _selectedRememberedAccount;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A3D62).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            selectedAccount == null
                ? 'Choose existing account'
                : 'Welcome back',
            style: const TextStyle(
              color: Color(0xFF0A3D62),
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            selectedAccount == null
                ? 'Select your saved KMFRI account to continue.'
                : 'Enter your password to unlock this account.',
            style: const TextStyle(color: Color(0xFF667085), fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (selectedAccount == null) ...[
            ...accounts.map((account) {
              final displayName = account.name.trim().isEmpty
                  ? 'Saved account'
                  : account.name.trim();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: const Color(0xFFF7FAFD),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      if (!widget.isOnline) {
                        context
                            .read<MobileAuthCubit>()
                            .selectRememberedAccountOffline(
                              userId: account.userId,
                            );
                      } else {
                        setState(() {
                          _selectedRememberedAccount = account;
                          _passwordController.clear();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 21,
                            backgroundColor: Color(0xFFE4F1FC),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF005B96),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF0A3D62),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (!widget.isOnline)
                                  const Text(
                                    'Tap to unlock with Biometrics / PIN',
                                    style: TextStyle(
                                      color: Color(0xFF16856B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            !widget.isOnline
                                ? Icons.fingerprint_rounded
                                : Icons.arrow_forward_rounded,
                            color: const Color(0xFF005B96),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ] else ...[
            _loginForm(),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => setState(() {
                  _selectedRememberedAccount = null;
                  _passwordController.clear();
                }),
                child: const Text('Choose a different account'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _useAlternativeSignIn = true;
              _selectedRememberedAccount = null;
              _passwordController.clear();
            }),
            icon: const Icon(Icons.password_rounded),
            label: const Text('Use another way'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: const Color(0xFF0A3D62),
              side: const BorderSide(color: Color(0xFFDCE8F5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signInCard({required bool hasRememberedAccounts}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A3D62).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasRememberedAccounts ? 'Sign in another way' : 'Sign In',
            style: const TextStyle(
              color: Color(0xFF0A3D62),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isStaff
                ? 'Enter your KMFRI Staff Number and Password'
                : 'Enter your registered Email and Password',
            style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
          ),
          const SizedBox(height: 20),
          _accountTypeSelector(),
          const SizedBox(height: 20),
          _loginForm(),
          if (hasRememberedAccounts) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() {
                _useAlternativeSignIn = false;
                _passwordController.clear();
              }),
              child: const Text('Back to existing account'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _accountTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isStaff) {
                  setState(() {
                    _isStaff = true;
                    _usernameController.clear();
                    _passwordController.clear();
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _isStaff ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isStaff
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 18,
                      color: _isStaff
                          ? const Color(0xFF005B96)
                          : const Color(0xFF667085),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Staff',
                      style: TextStyle(
                        fontWeight: _isStaff
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _isStaff
                            ? const Color(0xFF0A3D62)
                            : const Color(0xFF667085),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isStaff) {
                  setState(() {
                    _isStaff = false;
                    _usernameController.clear();
                    _passwordController.clear();
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: !_isStaff ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isStaff
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 18,
                      color: !_isStaff
                          ? const Color(0xFF005B96)
                          : const Color(0xFF667085),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Intern / Attaché',
                      style: TextStyle(
                        fontWeight: !_isStaff
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: !_isStaff
                            ? const Color(0xFF0A3D62)
                            : const Color(0xFF667085),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginForm() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedRememberedAccount != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8FD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD7EAFB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue as',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.4,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedRememberedAccount!.name.trim().isNotEmpty
                      ? _selectedRememberedAccount!.name.trim()
                      : 'Saved account',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A3D62),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_selectedRememberedAccount == null)
          TextFormField(
            controller: _usernameController,
            keyboardType: _isStaff
                ? TextInputType.text
                : TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A3D62),
            ),
            decoration: InputDecoration(
              labelText: _isStaff ? 'Staff Number' : 'Email Address',
              hintText: _isStaff ? 'staff number' : 'user@gmail.com',
              prefixIcon: Icon(
                _isStaff ? Icons.badge_outlined : Icons.email_outlined,
                color: const Color(0xFF005B96),
              ),
              filled: true,
              fillColor: const Color(0xFFFAFCFE),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8EEF7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8EEF7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF005B96),
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              final username = value?.trim() ?? '';
              if (username.isEmpty) {
                return _isStaff
                    ? 'Enter your staff number.'
                    : 'Enter your email.';
              }
              if (!_isStaff &&
                  !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(username)) {
                return 'Enter a valid email address.';
              }
              return null;
            },
          ),
        if (_selectedRememberedAccount == null) const SizedBox(height: 16),
        if (_selectedRememberedAccount != null &&
            _selectedRememberedAccount!.identifier.trim().isNotEmpty &&
            !_selectedRememberedAccount!.identifier.contains('@')) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8FD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD7EAFB)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 20,
                  color: Color(0xFF005B96),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Staff Number',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _selectedRememberedAccount!.identifier.trim(),
                  style: const TextStyle(
                    color: Color(0xFF0A3D62),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        BlocBuilder<MobileAuthCubit, MobileAuthState>(
          builder: (context, state) => TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A3D62),
            ),
            decoration: InputDecoration(
              labelText: _selectedRememberedAccount == null
                  ? 'Password'
                  : 'Account password',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF005B96),
              ),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF667085),
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFFAFCFE),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8EEF7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8EEF7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF005B96),
                  width: 2,
                ),
              ),
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? _selectedRememberedAccount == null
                      ? 'Enter your password.'
                      : 'Enter your account password.'
                : null,
          ),
        ),
        const SizedBox(height: 22),
        BlocBuilder<MobileAuthCubit, MobileAuthState>(
          builder: (context, state) {
            return ElevatedButton(
              onPressed: state.isBusy ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: const Color(0xFF0A3D62),
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: const Color(0xFF0A3D62).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: state.isBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedRememberedAccount != null
                              ? 'UNLOCK ACCOUNT'
                              : _isStaff
                              ? 'SIGN IN AS STAFF'
                              : 'SIGN IN AS INTERN',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            );
          },
        ),
      ],
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRememberedAccount != null) {
      await context.read<MobileAuthCubit>().continueWithRememberedAccount(
        isOnline: widget.isOnline,
        userId: _selectedRememberedAccount!.userId,
        password: _passwordController.text,
      );
      _passwordController.clear();
      return;
    }

    await context.read<MobileAuthCubit>().signIn(
      isOnline: widget.isOnline,
      isStaff: _isStaff,
      username: _usernameController.text,
      password: _passwordController.text,
    );
    _passwordController.clear();
  }

  Widget _errorMessage(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEBE9),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFCDD2)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFD32F2F),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF9F3027),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
