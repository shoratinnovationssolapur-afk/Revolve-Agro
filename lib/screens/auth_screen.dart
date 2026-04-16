import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import '../widgets/language_selector.dart';
import 'admin/admin_dashboard_page.dart';
import 'admin/super_admin_dashboard_page.dart';
import 'welcome_screen.dart';
import 'user_dashboard.dart';
import 'product_list.dart';

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
      case 'invalid-email': return context.l10n.text('invalid_email');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': return context.l10n.text('incorrect_email_password');
      case 'email-already-in-use': return context.l10n.text('email_registered_login');
      case 'weak-password': return context.l10n.text('weak_password');
      case 'too-many-requests': return context.l10n.text('too_many_attempts');
      default: return e.message ?? context.l10n.text('auth_failed');
    }
  }

  Future<void> _showValidationPopup(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.text('incomplete_form'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.text('ok')))],
      ),
    );
  }

  void _goToWelcomeScreen() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const WelcomeScreen()), (route) => false);
  }

  Future<void> _handleAuth() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      await _showValidationPopup(context.l10n.text('please_fill_email_password'));
      return;
    }
    if (!isLogin && (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty)) {
      await _showValidationPopup(context.l10n.text('please_fill_name_phone'));
      return;
    }

    setState(() => isLoading = true);
    try {
      if (isLogin) {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
        final data = userDoc.data();
        if (!userDoc.exists || data?['role'] == 'Blocked' || data?['isDeleted'] == true) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            setState(() => isLoading = false);
            await _showValidationPopup("This account has been deactivated.");
          }
          return;
        }
        if (mounted) {
          final role = data?['role'] ?? "User";
          if (role == "SuperAdmin") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuperAdminDashboardPage()));
          else if (role == "Admin") Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
          else Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserDashboard()));
        }
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'role': widget.role,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserDashboard()));
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendlyAuthMessage(e))));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppShell(
      backgroundImage: 'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?q=80&w=2070&auto=format&fit=crop',
      overlayOpacity: 0.5,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                      onPressed: _goToWelcomeScreen,
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                    ),
                    const LanguageSelector(),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  isLogin ? l10n.text('welcome_back') : l10n.text('create_your_account'),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  'Access your Revolve Agro account',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                ),
                const SizedBox(height: 40),
                AppGlassCard(
                  color: Colors.white.withOpacity(0.15),
                  child: Column(
                    children: [
                      _buildToggle(),
                      const SizedBox(height: 30),
                      if (!isLogin) ...[
                        _buildField(_nameController, l10n.text('full_name'), Icons.person_outline),
                        const SizedBox(height: 20),
                        _buildField(_phoneController, l10n.text('phone_number'), Icons.phone_outlined, TextInputType.phone),
                        const SizedBox(height: 20),
                      ],
                      _buildField(_emailController, l10n.text('email_address'), Icons.email_outlined, TextInputType.emailAddress),
                      const SizedBox(height: 20),
                      _buildPasswordField(_passwordController, l10n.text('password'), obscurePassword, () => setState(() => obscurePassword = !obscurePassword)),
                      const SizedBox(height: 30),
                      if (isLoading)
                        const CircularProgressIndicator(color: Colors.white)
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7BB960),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text(isLogin ? l10n.text('login') : l10n.text('sign_up'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const RevolveAgroProducts()));
                            },
                            icon: const Icon(Icons.storefront_outlined, color: Colors.white70, size: 18),
                            label: Text(l10n.text('browse_products_directly'), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _toggleBtn('Login', isLogin, () => setState(() => isLogin = true)),
          _toggleBtn('Register', !isLogin, () => setState(() => isLogin = false)),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: active ? const Color(0xFF7BB960) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, [TextInputType type = TextInputType.text]) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7BB960))),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscure, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.6)),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white.withOpacity(0.6)),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7BB960))),
      ),
    );
  }
}
