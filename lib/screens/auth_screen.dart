import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/language_selector.dart';
import 'admin_orders_page.dart';
import 'product_list.dart';
import 'welcome_screen.dart';

class AuthScreen extends StatefulWidget {
  final String role;

  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const String _defaultAdminCode = String.fromEnvironment(
    'ADMIN_SIGNUP_CODE',
    defaultValue: 'REVOLVE_ADMIN_2026',
  );

  bool isLogin = true;
  bool isLoading = false;
  bool obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _adminCodeController = TextEditingController();

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered. Please log in instead.';
      case 'weak-password':
        return 'Password should be at least 6 characters long.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Auth.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<void> _showValidationPopup(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Incomplete Form'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
      await _showValidationPopup('Please fill in email and password.');
      return;
    }

    if (!isLogin &&
        (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty)) {
      await _showValidationPopup('Please fill in full name and phone number before signing up.');
      return;
    }

    if (!isLogin && widget.role == 'Admin') {
      if (_adminCodeController.text.trim().isEmpty) {
        await _showValidationPopup('Please enter the admin code to create an admin account.');
        return;
      }

      if (_adminCodeController.text.trim() != _defaultAdminCode) {
        await _showValidationPopup('Invalid admin code. Only authorized admins can sign up.');
        return;
      }
    }

    setState(() => isLoading = true);
    try {
      if (isLogin) {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        final actualRole = userDoc.data()?['role'] ?? "User";

        if (mounted) {
          if (actualRole == "Admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminOrdersPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => RevolveAgroProducts()),
            );
          }
        }
      } else {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'role': widget.role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  widget.role == "Admin" ? const AdminOrdersPage() : RevolveAgroProducts(),
            ),
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
        SnackBar(content: Text("Database Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
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
    final accent = isAdmin ? const Color(0xFF8C5B1C) : const Color(0xFF2F6A3E);
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withOpacity(0.14),
              const Color(0xFFF7F3E8),
              const Color(0xFFF5F8EE),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton.filledTonal(
                  onPressed: _goToWelcomeScreen,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerRight,
                  child: LanguageSelector(),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, accent.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          isAdmin ? Icons.admin_panel_settings_rounded : Icons.eco_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAdmin ? l10n.text('admin_workspace') : l10n.text('user_workspace'),
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isLogin ? l10n.text('welcome_back') : l10n.text('create_your_account'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF183020),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(26),
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
                                if (isAdmin) ...[
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _adminCodeController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: l10n.text('admin_code'),
                                      prefixIcon: const Icon(Icons.security_rounded),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
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
                                    onPressed: () {
                                      setState(() => obscurePassword = !obscurePassword);
                                    },
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.tips_and_updates_outlined, color: accent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isLogin
                                      ? l10n.text('login_hint')
                                      : l10n.text('signup_hint'),
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (isLoading)
                          Center(
                            child: CircularProgressIndicator(color: accent),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _handleAuth,
                            style: ElevatedButton.styleFrom(backgroundColor: accent),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(
                              isLogin ? l10n.text('continue_to_dashboard') : l10n.text('create_account'),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () => setState(() => isLogin = !isLogin),
                            child: Text(
                              isLogin
                                  ? l10n.text('dont_have_account')
                                  : l10n.text('already_have_account'),
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
