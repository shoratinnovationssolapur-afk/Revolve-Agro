import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/language_selector.dart';
import 'auth_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF1F5E6),
              Color(0xFFF7F3E8),
              Color(0xFFFCEFD9),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
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

                /// 🔥 TITLE CHANGED (ONLY THIS LINE MODIFIED)
                const Text(
                  "Welcome to Revolve Agro",
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183020),
                  ),
                ),

                const SizedBox(height: 10),

                /// ❌ subtitle NOT changed (as you didn’t ask)
                Text(
                  l10n.text('choose_experience_subtitle'),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 26),

                Expanded(
                  child: Column(
                    children: [

                      /// 👤 USER
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

                      /// 🛠 ADMIN
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

                      /// 🔥 NEW SUPER ADMIN (ADDED ONLY)
                      _RoleCard(
                        title: "Super Admin Login",
                        subtitle: "Manage admins, control platform and monitor system activity.",
                        icon: Icons.workspace_premium_outlined,
                        accent: const Color(0xFF6A5ACD),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(role: "SuperAdmin"),
                            ),
                          );
                        },
                      ),

                      const Spacer(),

                      /// FOOTER (UNCHANGED)
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
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.12),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
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
                  children: <Widget>[
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
    );
  }
}