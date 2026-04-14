import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import '../widgets/language_selector.dart';
import 'admin/admin_dashboard_page.dart';
import 'product_list.dart';
import 'admin/super_admin_dashboard_page.dart';
import 'welcome_screen.dart';

// ✅ ADDED
import 'user_dashboard.dart';

class AuthScreen extends StatefulWidget {
  final String role;

  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  static const String _defaultAdminCode = String.fromEnvironment(
    'ADMIN_SIGNUP_CODE',
    defaultValue: 'REVOLVE_ADMIN_2026',
  );

  static const String _defaultSuperAdminCode = String.fromEnvironment(
    'SUPER_ADMIN_SIGNUP_CODE',
    defaultValue: 'REVOLVE_SUPER_ADMIN_2026',
  );

  bool isLogin = true;
  bool isLoading = false;
  bool obscurePassword = true;

  late final AnimationController _pageController;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _adminCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return context.l10n.text('invalid_email');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return context.l10n.text('incorrect_email_password');
      case 'email-already-in-use':
        return context.l10n.text('email_registered_login');
      case 'weak-password':
        return context.l10n.text('weak_password');
      case 'operation-not-allowed':
        return context.l10n.text('email_password_disabled');
      case 'too-many-requests':
        return context.l10n.text('too_many_attempts');
      default:
        return e.message ?? context.l10n.text('auth_failed');
    }
  }

  Future<void> _showValidationPopup(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.text('incomplete_form')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.text('ok')),
          ),
        ],
      ),
    );
  }

  void _goToWelcomeScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
    );
  }

  Future<void> _handleAuth() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      await _showValidationPopup(context.l10n.text('please_fill_email_password'));
      return;
    }

    if (!isLogin &&
        (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty)) {
      await _showValidationPopup(context.l10n.text('please_fill_name_phone'));
      return;
    }

    // ✅ ADMIN + SUPER ADMIN VALIDATION
    if (!isLogin && (widget.role == 'Admin' || widget.role == 'SuperAdmin')) {
      if (_adminCodeController.text.trim().isEmpty) {
        await _showValidationPopup(
          widget.role == 'SuperAdmin'
              ? context.l10n.text('please_enter_super_admin_code')
              : context.l10n.text('please_enter_admin_code'),
        );
        return;
      }

      if (widget.role == 'Admin' &&
          _adminCodeController.text.trim() != _defaultAdminCode) {
        await _showValidationPopup(context.l10n.text('invalid_admin_code'));
        return;
      }

      if (widget.role == 'SuperAdmin' &&
          _adminCodeController.text.trim() != _defaultSuperAdminCode) {
        await _showValidationPopup('Invalid super admin code.');
        return;
      }
    }

    if (!isLogin && widget.role == 'SuperAdmin') {
      if (_adminCodeController.text.trim().isEmpty) {
        await _showValidationPopup('Please enter the super admin code to create a super admin account.');
        return;
      }

      if (_adminCodeController.text.trim() != _defaultSuperAdminCode) {
        await _showValidationPopup('Invalid super admin code.');
        return;
      }

      final existingSuperAdmins = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'SuperAdmin')
          .limit(1)
          .get();
      if (existingSuperAdmins.docs.isNotEmpty) {
        await _showValidationPopup('Super Admin already exists. Only one Super Admin is allowed.');
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // Inside _handleAuth() -> if (isLogin) { ... }

        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

// 1. Fetch the user document
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

// 2. CHECK IF BLOCKED OR DELETED
        final data = userDoc.data();
        if (!userDoc.exists || data?['role'] == 'Blocked' || data?['isDeleted'] == true) {
          await FirebaseAuth.instance.signOut(); // 🔥 Force Logout
          if (mounted) {
            setState(() => isLoading = false);
            await _showValidationPopup("This account has been deactivated or deleted by the Admin.");
          }
          return; // Stop the login process
        }

        final actualRole = data?['role'] ?? "User";

// ... existing navigation logic (SuperAdmin, Admin, UserDashboard) ...

        if (mounted) {
          if (actualRole == "SuperAdmin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SuperAdminDashboardPage(),
              ),
            );
          } else if (actualRole == "Admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDashboardPage(),
              ),
            );
          } else {
            // ✅ CHANGED HERE
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserDashboard()),
            );
          }
        }
      } else {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

// Inside _handleAuth() -> else { ... signup logic }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'role': widget.role, // This ensures 'SuperAdmin' is saved
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          // Use a clean navigation to avoid 'nothing happening'
          Widget nextScreen;
          if (widget.role == "SuperAdmin") {
            nextScreen = const SuperAdminDashboardPage();
          } else if (widget.role == "Admin") {
            nextScreen = const AdminDashboardPage();
          } else {
            nextScreen = RevolveAgroProducts();
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
                (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase auth error [${e.code}]: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyAuthMessage(e))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.textWithArgs('database_error', {'error': '$e'}))),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == 'Admin';
    final isSuperAdmin = widget.role == 'SuperAdmin';
    final accent = isSuperAdmin
        ? const Color(0xFF4B2A63)
        : (isAdmin ? const Color(0xFF8C5B1C) : const Color(0xFF2F6A3E));
    final l10n = context.l10n;
    final pageAnim = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOutCubic,
    );

    return Scaffold(
      body: AppShell(
        colors: [
          accent.withOpacity(0.14),
          const Color(0xFFF7F3E8),
          const Color(0xFFF5F8EE),
        ],
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: _AgriBackdrop(
                    accent: accent,
                    animation: pageAnim,
                  ),
                ),
              ),
              SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    IconButton.filledTonal(
                      onPressed: _goToWelcomeScreen,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const LanguageSelector(),
                  ],
                ),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: pageAnim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(pageAnim),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compactHeader = constraints.maxWidth < 370;
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.75),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: compactHeader
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 72,
                                      width: 72,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            accent,
                                            accent.withOpacity(0.70),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withOpacity(0.25),
                                            blurRadius: 18,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isSuperAdmin
                                            ? Icons.security_rounded
                                            : isAdmin
                                                ? Icons
                                                    .admin_panel_settings_rounded
                                                : Icons.eco_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isSuperAdmin
                                          ? l10n.text('super_admin_workspace')
                                          : isAdmin
                                              ? l10n.text('admin_workspace')
                                              : l10n.text('farmer_workspace'),
                                      style: TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      child: Text(
                                        isLogin
                                            ? l10n.text('welcome_back')
                                            : l10n.text('create_your_account'),
                                        key: ValueKey(isLogin),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF183020),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Container(
                                      height: 72,
                                      width: 72,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            accent,
                                            accent.withOpacity(0.70),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withOpacity(0.25),
                                            blurRadius: 18,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isSuperAdmin
                                            ? Icons.security_rounded
                                            : isAdmin
                                                ? Icons
                                                    .admin_panel_settings_rounded
                                                : Icons.eco_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isSuperAdmin
                                                ? l10n.text(
                                                    'super_admin_workspace')
                                                : isAdmin
                                                    ? l10n.text(
                                                        'admin_workspace')
                                                    : l10n.text(
                                                        'farmer_workspace'),
                                            style: TextStyle(
                                              color: accent,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            child: Text(
                                              isLogin
                                                  ? l10n.text('welcome_back')
                                                  : l10n.text(
                                                      'create_your_account'),
                                              key: ValueKey(isLogin),
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF183020),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ===== REMAINING UI EXACT SAME =====

                FadeTransition(
                  opacity: pageAnim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(pageAnim),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: Colors.black.withOpacity(0.05),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: accent.withOpacity(0.65),
                              width: 1.4,
                            ),
                          ),
                          labelStyle: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.90),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.75),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2EADA),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _modeButton(
                                  label: l10n.text('login'),
                                  selected: isLogin,
                                  accent: accent,
                                  onTap: () => setState(() => isLogin = true),
                                ),
                              ),
                              Expanded(
                                child: _modeButton(
                                  label: l10n.text('sign_up'),
                                  selected: !isLogin,
                                  accent: accent,
                                  onTap: () => setState(() => isLogin = false),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Column(
                            key: ValueKey(isLogin),
                            children: [
                              if (!isLogin) ...[
                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.text('full_name'),
                                    prefixIcon: const Icon(Icons.person_outline_rounded),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: l10n.text('phone_number'),
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14), // Added spacing
                                // FIXED: Properly separated the Admin/SuperAdmin code field
                                if (isAdmin || isSuperAdmin) ...[
                                  TextField(
                                    controller: _adminCodeController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: isSuperAdmin
                                          ? 'Super Admin Code'
                                          : l10n.text('admin_code'),
                                      prefixIcon: const Icon(Icons.security_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              ],
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: l10n.text('email_address'),
                                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _passwordController,
                                obscureText: obscurePassword,
                                decoration: InputDecoration(
                                  labelText: l10n.text('password'),
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => obscurePassword = !obscurePassword),
                                    icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.tips_and_updates_outlined, color: accent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isLogin
                                      ? l10n.text('login_hint')
                                      : l10n.text('signup_hint'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (isLoading)
                          Center(child: CircularProgressIndicator(color: accent))
                        else
                          _AgriPrimaryButton(
                            accent: accent,
                            icon: Icons.arrow_forward_rounded,
                            label: isLogin
                                ? l10n.text('continue_to_dashboard')
                                : l10n.text('create_account'),
                            onPressed: _handleAuth,
                          ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeButton({
    required String label,
    required bool selected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF214B2D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AgriPrimaryButton extends StatefulWidget {
  final Color accent;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _AgriPrimaryButton({
    required this.accent,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_AgriPrimaryButton> createState() => _AgriPrimaryButtonState();
}

class _AgriPrimaryButtonState extends State<_AgriPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.accent;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        a,
        Color.lerp(a, const Color(0xFF2F6A3E), 0.35) ?? a,
      ],
    );

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.98 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: a.withOpacity(0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.grass_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(widget.icon, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgriBackdrop extends StatelessWidget {
  final Color accent;
  final Animation<double> animation;

  const _AgriBackdrop({
    required this.accent,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final leaf = Color.lerp(accent, const Color(0xFF2F6A3E), 0.45) ?? accent;
    final seed = Color.lerp(accent, const Color(0xFFD9952E), 0.35) ?? accent;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return Stack(
          children: [
            Positioned(
              top: -30 + (1 - t) * 14,
              right: -18,
              child: Transform.rotate(
                angle: -0.20 + (1 - t) * 0.12,
                child: Icon(
                  Icons.park_rounded,
                  size: 140,
                  color: leaf.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              top: 160 + (1 - t) * 18,
              left: -26,
              child: Transform.rotate(
                angle: 0.30 - (1 - t) * 0.10,
                child: Icon(
                  Icons.eco_rounded,
                  size: 170,
                  color: leaf.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -38 + (1 - t) * 22,
              right: -26,
              child: Transform.rotate(
                angle: 0.05 + (1 - t) * 0.10,
                child: Icon(
                  Icons.grain_rounded,
                  size: 190,
                  color: seed.withOpacity(0.08),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
