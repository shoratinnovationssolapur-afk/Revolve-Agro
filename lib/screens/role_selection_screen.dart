import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import '../widgets/language_selector.dart';
import 'auth_screen.dart';
import 'Vendor_Listing_Page.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppShell(
      backgroundImage: 'https://images.unsplash.com/photo-1495107336281-118e6e58e493?q=80&w=2070&auto=format&fit=crop',
      overlayOpacity: 0.5,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: LanguageSelector(),
                      ),

                      const SizedBox(height: 18),

                      AppSectionHeading(
                        title: l10n.text('choose_experience_title'),
                        subtitle: l10n.text('choose_experience_subtitle'),
                        color: Colors.white,
                      ),

                      const SizedBox(height: 26),

                      // User/Farmer Login Card
                      _RoleCard(
                        title: l10n.text('user_login'),
                        subtitle: l10n.text('user_login_subtitle'),
                        icon: Icons.person_outline_rounded,
                        accent: const Color(0xFF7BB960),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(role: "User"),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // Vendor Login Card
                      _RoleCard(
                        title: "Vendor Login",
                        subtitle: "Manage your shop and fulfill farmer orders",
                        icon: Icons.storefront_outlined,
                        accent: const Color(0xFFD9952E),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(role: "Vendor"),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      Center(
                        child: Column(
                          children: [
                            Text(
                              "Want to partner with Revolve Agro?",
                              style: TextStyle(color: Colors.white.withOpacity(0.8)),
                            ),
                            TextButton(
                              onPressed: () {
                                 Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorListingPage()));
                              },
                              child: const Text(
                                "Register as a Vendor",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7BB960),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Multilingual Support Info
                      AppGlassCard(
                        color: Colors.white.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              const Icon(Icons.language_rounded, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.text('multilingual_support'),
                                  style: const TextStyle(height: 1.45, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: AppGlassCard(
            color: Colors.white.withOpacity(0.15),
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: accent, size: 32),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}