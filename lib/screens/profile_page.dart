import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/language_selector.dart';
import 'admin_dashboard_page.dart';
import 'auth_screen.dart';
import 'product_list.dart';
import 'super_admin_dashboard_page.dart';
import 'welcome_screen.dart';

class ProfilePage extends StatefulWidget {
  final String role;

  const ProfilePage({super.key, required this.role});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _savingNotifications = false;
  bool _savingLocation = false;

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No logged-in user');
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Future<void> _updateSetting(String key, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      key: value,
    }, SetOptions(merge: true));
  }

  Future<void> _logout() async {
    final l10n = context.l10n;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.text('logout')),
        content: Text(l10n.text('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.text('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.text('logout')),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen(role: widget.role)),
          (route) => false,
    );
  }

  void _goToHome() {
    Widget destination;
    if (widget.role == 'SuperAdmin') {
      destination = const SuperAdminDashboardPage();
    } else if (widget.role == 'Admin') {
      destination = const AdminDashboardPage();
    } else {
      destination = RevolveAgroProducts();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => destination),
          (route) => false,
    );
  }

  void _goToWelcome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => WelcomeScreen(preferredRole: widget.role),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == 'Admin';
    final isSuperAdmin = widget.role == 'SuperAdmin';
    final isAnyAdmin = isAdmin || isSuperAdmin;

    final accent = isSuperAdmin
        ? const Color(0xFF4B2A63)
        : (isAdmin ? const Color(0xFF8C5B1C) : const Color(0xFF2F6A3E));
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withOpacity(0.14),
              const Color(0xFFF7F3E8),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: _loadProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data?.data() ?? <String, dynamic>{};
              final name = data['name']?.toString().trim();
              final email = data['email']?.toString().trim();
              final phone = data['phone']?.toString().trim();
              final notificationsEnabled = data['notificationsEnabled'] as bool? ?? true;
              final locationEnabled = data['locationEnabled'] as bool? ?? !isAnyAdmin;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: _goToHome,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        const LanguageSelector(),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withOpacity(0.72)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Icon(
                              isSuperAdmin
                                  ? Icons.verified_user_rounded
                                  : (isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded),
                              size: 34,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            name?.isNotEmpty == true ? name! : l10n.text('profile'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            email?.isNotEmpty == true ? email! : l10n.text('no_email_found'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                            ),
                          ),
                          if (phone?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              phone!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Text(
                              isSuperAdmin
                                  ? "Super Admin Workspace"
                                  : (isAdmin ? l10n.text('admin_workspace') : l10n.text('user_workspace')),

                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      l10n.text('account_overview'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF183020),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      icon: Icons.badge_outlined,
                      title: l10n.text('account_role'),
                      value: widget.role,
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.phone_outlined,
                      title: l10n.text('phone_number'),
                      value: phone?.isNotEmpty == true ? phone! : l10n.text('not_added_yet'),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      l10n.text('settings'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF183020),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingTile(
                      icon: Icons.notifications_active_outlined,
                      title: l10n.text('notifications'),
                      subtitle: isAnyAdmin
                          ? l10n.text('admin_notifications_subtitle')
                          : l10n.text('user_notifications_subtitle'),
                      trailing: _savingNotifications
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Switch(
                        value: notificationsEnabled,
                        onChanged: (value) async {
                          setState(() => _savingNotifications = true);
                          try {
                            await _updateSetting('notificationsEnabled', value);
                          } finally {
                            if (mounted) {
                              setState(() => _savingNotifications = false);
                            }
                          }
                        },
                        activeThumbColor: accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingTile(
                      icon: isAnyAdmin ? Icons.campaign_outlined : Icons.my_location_rounded,
                      title: isAnyAdmin ? l10n.text('order_alerts') : l10n.text('location_access'),
                      subtitle: isAnyAdmin
                          ? (isSuperAdmin
                          ? "Receive notifications for all platform activity"
                          : l10n.text('order_alerts_subtitle'))
                          : l10n.text('location_access_subtitle'),
                      trailing: _savingLocation
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Switch(
                        value: locationEnabled,
                        onChanged: (value) async {
                          setState(() => _savingLocation = true);
                          try {
                            await _updateSetting('locationEnabled', value);
                          } finally {
                            if (mounted) {
                              setState(() => _savingLocation = false);
                            }
                          }
                        },
                        activeThumbColor: accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingTile(
                      icon: Icons.translate_rounded,
                      title: l10n.text('app_language'),
                      subtitle: l10n.text('app_language_subtitle'),
                      trailing: const LanguageSelector(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _goToHome,
                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                      icon: Icon(isSuperAdmin ? Icons.admin_panel_settings_outlined : Icons.space_dashboard_outlined),
                      label: Text(
                        isSuperAdmin
                            ? "Go to Super Admin Dashboard"
                            : (isAdmin ? l10n.text('go_to_admin_dashboard') : l10n.text('go_to_marketplace')),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _goToWelcome,
                      icon: const Icon(Icons.home_outlined),
                      label: Text(l10n.text('back_to_welcome')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(l10n.text('logout')),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1E1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF2F6A3E)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF183020),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5EEDC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF8C5B1C)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF183020),
                  ),
                ),
                const SizedBox(height: 4),
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
          trailing,
        ],
      ),
    );
  }
}