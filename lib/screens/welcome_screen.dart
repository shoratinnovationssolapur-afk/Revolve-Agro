import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/language_selector.dart';
import 'AdminOrdersPage.dart';
import 'auth_screen.dart';
import 'product_list.dart';
import 'role_selection_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final String? preferredRole;

  const WelcomeScreen({super.key, this.preferredRole});

  Future<void> _handleContinue(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (preferredRole == 'Admin') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen(role: 'Admin')),
        );
        return;
      }

      if (preferredRole == 'User') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen(role: 'User')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final role = userDoc.data()?['role']?.toString() ?? 'User';

    if (!context.mounted) {
      return;
    }

    if (role == 'Admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminOrdersPage()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RevolveAgroProducts()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE7F1D9),
              Color(0xFFF7F3E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -60,
                right: -40,
                child: _glowCircle(const Color(0x55D9952E), 190),
              ),
              Positioned(
                top: 120,
                left: -70,
                child: _glowCircle(const Color(0x443E8A4E), 180),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.82),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.eco, color: Color(0xFF2F6A3E)),
                              const SizedBox(width: 10),
                              Text(
                                l10n.text('app_name'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF214B2D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const LanguageSelector(),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 78,
                            width: 78,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2F6A3E), Color(0xFF6BAA54)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.agriculture, color: Colors.white, size: 38),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            l10n.text('grow_smarter_title'),
                            style: TextStyle(
                              fontSize: 34,
                              height: 1.08,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF183020),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.text('grow_smarter_subtitle'),
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.55,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              _StatPill(label: l10n.text('trusted_products')),
                              const SizedBox(width: 10),
                              _StatPill(label: l10n.text('easy_checkout')),
                            ],
                          ),
                          const SizedBox(height: 26),
                          ElevatedButton.icon(
                            onPressed: () => _handleContinue(context),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(l10n.text('continue')),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RevolveAgroProducts()),
                              );
                            },
                            icon: const Icon(Icons.storefront_outlined),
                            label: Text(l10n.text('browse_products_directly')),
                          ),
                        ],
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

  Widget _glowCircle(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;

  const _StatPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E5C9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8A5D1A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
