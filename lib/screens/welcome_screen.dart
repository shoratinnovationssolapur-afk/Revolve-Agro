import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/language_selector.dart';
import '../utils/helpline.dart';
import 'admin/admin_dashboard_page.dart';
import 'auth_screen.dart';
import 'role_selection_screen.dart';
import 'admin/super_admin_dashboard_page.dart';
import 'user_dashboard.dart';
import 'product_list.dart';
import '../widgets/app_shell.dart';

class WelcomeScreen extends StatefulWidget {
  final String? preferredRole;
  final bool firebaseReady;

  const WelcomeScreen({
    super.key,
    this.preferredRole,
    this.firebaseReady = true,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fade = CurvedAnimation(parent: _introController, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!widget.firebaseReady) return;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final String role = userDoc.data()?['role']?.toString() ?? 'User';
      if (!mounted) return;

      if (role == 'SuperAdmin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SuperAdminDashboardPage()));
      } else if (role == 'Admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
      } else {
        // ✅ Ensure it goes to the NEW modern dashboard
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserDashboard()));
      }
    } catch (e) {
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => const RoleSelectionScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppShell(
      backgroundImage: 'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?q=80&w=2070&auto=format&fit=crop',
      overlayOpacity: 0.3,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _fade,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.eco, color: Colors.white, size: 28),
                    ),
                    const LanguageSelector(),
                  ],
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Solution\nModern Agriculture',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.text('grow_smarter_subtitle'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: Colors.white.withOpacity(0.5)),
                              ),
                            ),
                            child: Text(
                              l10n.text('continue'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () {
                               // ✅ Ensure it goes to the NEW modern product list
                               Navigator.push(context, MaterialPageRoute(builder: (context) => const RevolveAgroProducts()));
                            },
                            child: Text(
                              l10n.text('browse_products_directly'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
