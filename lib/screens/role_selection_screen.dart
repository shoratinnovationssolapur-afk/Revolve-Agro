import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import '../widgets/language_selector.dart';
import 'auth_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: AppShell(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 38),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(height: 10),

                      const Align(
                        alignment: Alignment.centerRight,
                        child: LanguageSelector(),
                      ),

                      const SizedBox(height: 18),

                      // Using the new Section Heading widget from the incoming branch
                      AppSectionHeading(
                        title: l10n.text('choose_experience_title'),
                        subtitle: l10n.text('choose_experience_subtitle'),
                      ),

                      const SizedBox(height: 26),

                      // User Card
                      _RoleCard(
                        title: l10n.text('user_login'),
                        subtitle: l10n.text('user_login_subtitle'),
                        icon: Icons.person_outline_rounded,
                        accent: const Color(0xFF2F6A3E),
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

                      // Admin Card
                      _RoleCard(
                        title: l10n.text('admin_login'),
                        subtitle: l10n.text('admin_login_subtitle'),
                        icon: Icons.admin_panel_settings_outlined,
                        accent: const Color(0xFFD9952E),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(role: "Admin"),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // Super Admin Card (Integrated with your logic + new UI style)
                      _RoleCard(
                        title: 'Super Admin',
                        subtitle: 'Manage admins, control the platform, and monitor activity.',
                        icon: Icons.security_rounded,
                        accent: const Color(0xFF4B2A63),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(role: "SuperAdmin"),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // Multilingual Support Info
                      AppGlassCard(
<<<<<<< HEAD
                        child: Row(
                          children: [
                            const Icon(Icons.language_rounded, color: Color(0xFF2F6A3E)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.text('multilingual_support'),
                                style: const TextStyle(height: 1.45),
=======
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.language_rounded,
                                    color: Color(0xFF2F6A3E)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.text('multilingual_support'),
                                    style: const TextStyle(height: 1.45),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.88),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.language_rounded, color: Color(0xFF2F6A3E)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l10n.text('multilingual_support'),
                                      style: const TextStyle(height: 1.45),
                                    ),
                                  ),
                                ],
>>>>>>> 80dc2dafb33893ea3bdb23d4f8e6e71a8cb5c668
                              ),
                            ),
                          ],
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
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
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
                          color: Color(0xFF183020),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_rounded, color: Color(0xFF183020)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}