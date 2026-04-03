import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/language_selector.dart';
import 'admin_dashboard_page.dart';
import 'auth_screen.dart';
import 'product_list.dart';
import 'role_selection_screen.dart';
import 'super_admin_dashboard_page.dart';

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
  late final AnimationController _floatController;
  late final Animation<double> _heroFade;
  late final Animation<double> _heroScale;
  late final Animation<Offset> _cardOffset;
  late final Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);

    _heroFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOut),
    );
    _heroScale = Tween<double>(begin: 0.76, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _cardOffset = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.24, 1, curve: Curves.easeOutCubic),
      ),
    );
    _cardFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.22, 0.9, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!widget.firebaseReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App is getting ready. Please wait a moment.')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    // Handle flow for users NOT logged in
    if (currentUser == null) {
      if (widget.preferredRole == 'Admin') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen(role: 'Admin')),
        );
        return;
      }
      if (widget.preferredRole == 'SuperAdmin') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthScreen(role: 'SuperAdmin'),
          ),
        );
        return;
      }
      if (widget.preferredRole == 'User') {
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

    // Handle flow for ALREADY logged in users
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final String role = userDoc.data()?['role']?.toString() ?? 'User';

      if (!mounted) return;

      if (role == 'SuperAdmin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SuperAdminDashboardPage(),
          ),
        );
      } else if (role == 'Admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboardPage(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RevolveAgroProducts()),
        );
      }
    } catch (e) {
      debugPrint("Autologin Error: $e");
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_introController, _floatController]),
        builder: (context, child) {
          final floatValue = Curves.easeInOut.transform(_floatController.value);
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE7F1D9),
                  Color(0xFFF7F3E8),
                  Color(0xFFFFFBF2),
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compactLayout = isMarathi || constraints.maxHeight < 760;
                  final content = Stack(
                        children: [
                          Positioned(
                            top: -90 + (floatValue * 24),
                            right: -50,
                            child: _glowOrb(
                              size: 220,
                              colors: const [Color(0x55D9952E), Color(0x22F6C96C)],
                            ),
                          ),
                          Positioned(
                            top: 120 - (floatValue * 18),
                            left: -65,
                            child: _glowOrb(
                              size: 180,
                              colors: const [Color(0x443E8A4E), Color(0x223E8A4E)],
                            ),
                          ),
                          Positioned(
                            bottom: 230 - (floatValue * 12),
                            right: -30,
                            child: Transform.rotate(
                              angle: math.pi / 10,
                              child: _grainCard(),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              compactLayout ? 20 : 24,
                              compactLayout ? 18 : 24,
                              compactLayout ? 20 : 24,
                              compactLayout ? 20 : 30,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FadeTransition(
                                  opacity: _heroFade,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: compactLayout ? 12 : 14,
                                            vertical: compactLayout ? 8 : 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.82),
                                            borderRadius: BorderRadius.circular(30),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0x14214B2D),
                                                blurRadius: 16,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.eco, color: Color(0xFF2F6A3E)),
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Text(
                                                  l10n.text('app_name'),
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF214B2D),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const LanguageSelector(),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: compactLayout ? 16 : math.max(24, constraints.maxHeight * 0.08),
                                ),
                                FadeTransition(
                                  opacity: _heroFade,
                                  child: ScaleTransition(
                                    scale: _heroScale,
                                    child: Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: compactLayout ? 122 : 152,
                                            height: compactLayout ? 122 : 152,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(
                                                colors: [
                                                  const Color(0x336BAA54),
                                                  const Color(0x116BAA54),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                          Transform.translate(
                                            offset: Offset(0, -6 * floatValue),
                                            child: Container(
                                              height: compactLayout ? 82 : 102,
                                              width: compactLayout ? 82 : 102,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [Color(0xFF2F6A3E), Color(0xFF7BB960)],
                                                ),
                                                borderRadius: BorderRadius.circular(30),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0x332F6A3E),
                                                    blurRadius: 28,
                                                    offset: const Offset(0, 18),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.agriculture_rounded,
                                                color: Colors.white,
                                                size: 42,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: compactLayout ? 18 : 26),
                                FadeTransition(
                                  opacity: _cardFade,
                                  child: SlideTransition(
                                    position: _cardOffset,
                                    child: Container(
                                      padding: EdgeInsets.all(compactLayout ? 20 : 26),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.92),
                                        borderRadius: BorderRadius.circular(compactLayout ? 28 : 34),
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
                                            padding: EdgeInsets.symmetric(
                                              horizontal: compactLayout ? 12 : 14,
                                              vertical: compactLayout ? 8 : 10,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFF6E7C6), Color(0xFFF2D89C)],
                                              ),
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            child: Text(
                                              'Farm Commerce',
                                              style: TextStyle(
                                                color: Color(0xFF8A5D1A),
                                                fontWeight: FontWeight.w800,
                                                fontSize: compactLayout ? 12.5 : 14,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: compactLayout ? 12 : 18),
                                          Text(
                                            l10n.text('grow_smarter_title'),
                                            maxLines: compactLayout ? 2 : null,
                                            overflow: compactLayout ? TextOverflow.ellipsis : TextOverflow.visible,
                                            style: TextStyle(
                                              fontSize: compactLayout ? 28 : 34,
                                              height: 1.08,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF183020),
                                            ),
                                          ),
                                          SizedBox(height: compactLayout ? 10 : 14),
                                          Text(
                                            l10n.text('grow_smarter_subtitle'),
                                            maxLines: compactLayout ? 3 : null,
                                            overflow: compactLayout ? TextOverflow.ellipsis : TextOverflow.visible,
                                            style: TextStyle(
                                              fontSize: compactLayout ? 13 : 15,
                                              height: 1.55,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          SizedBox(height: compactLayout ? 14 : 22),
                                          Wrap(
                                            spacing: compactLayout ? 8 : 10,
                                            runSpacing: compactLayout ? 8 : 10,
                                            children: [
                                              _StatPill(
                                                label: l10n.text('trusted_products'),
                                                compact: compactLayout,
                                              ),
                                              _StatPill(
                                                label: l10n.text('easy_checkout'),
                                                compact: compactLayout,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: compactLayout ? 18 : 26),
                                          ElevatedButton.icon(
                                            onPressed: _handleContinue,
                                            icon: widget.firebaseReady
                                                ? const Icon(Icons.arrow_forward_rounded)
                                                : const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                            label: Text(
                                              widget.firebaseReady
                                                  ? l10n.text('continue')
                                                  : l10n.text('loading_app'),
                                            ),
                                          ),
                                          SizedBox(height: compactLayout ? 10 : 12),
                                          OutlinedButton.icon(
                                            onPressed: widget.firebaseReady
                                                ? () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => RevolveAgroProducts(),
                                                      ),
                                                    );
                                                  }
                                                : null,
                                            icon: const Icon(Icons.storefront_outlined),
                                            label: Text(l10n.text('browse_products_directly')),
                                          ),
                                          if (!widget.firebaseReady) ...[
                                            SizedBox(height: compactLayout ? 10 : 14),
                                            Row(
                                              children: [
                                                const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.2,
                                                    color: Color(0xFF2F6A3E),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    l10n.text('startup_hint'),
                                                    style: TextStyle(
                                                      color: Colors.grey.shade700,
                                                      height: 1.45,
                                                      fontSize: compactLayout ? 12 : 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                  if (isMarathi) {
                    return SizedBox(
                      height: constraints.maxHeight,
                      child: content,
                    );
                  }

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: content,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _glowOrb({required double size, required List<Color> colors}) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }

  Widget _grainCard() {
    return Opacity(
      opacity: 0.34,
      child: Container(
        width: 120,
        height: 150,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4E6C4), Color(0xFFE8D2A1)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(
          Icons.spa_outlined,
          color: Color(0xAA8A5D1A),
          size: 46,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final bool compact;

  const _StatPill({
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E5C9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color(0xFF8A5D1A),
          fontWeight: FontWeight.w700,
          fontSize: compact ? 12.5 : 14,
        ),
      ),
    );
  }
}
