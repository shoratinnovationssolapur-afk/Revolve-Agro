import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:ui';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import '../widgets/language_selector.dart';
import 'admin/admin_dashboard_page.dart';
import 'auth_screen.dart';
import 'product_list.dart';
import 'admin/super_admin_dashboard_page.dart';
import 'welcome_screen.dart';
import 'user_dashboard.dart';

class ProfilePage extends StatefulWidget {
  final String role;

  const ProfilePage({super.key, required this.role});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _fetchingLocation = false;

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Future.error(StateError('No logged-in user'));
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

  Future<void> _fetchAndSaveCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        
        // Fetching precise details like building, street, and locality
        final house = p.subThoroughfare ?? ''; // Building/House number
        final street = p.thoroughfare ?? ''; // Street name
        final landmark = p.subLocality ?? ''; // Locality/Landmark
        final city = p.locality ?? p.subAdministrativeArea ?? '';
        final pincode = p.postalCode ?? '';
        
        final fullPreciseAddress = '${house.isNotEmpty ? '$house, ' : ''}${street.isNotEmpty ? '$street, ' : ''}$landmark, $city - $pincode'.trim();
        
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'city': city,
            'landmark': landmark,
            'fullAddress': fullPreciseAddress,
            'pincode': pincode,
          });
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error fetching precise location: $e');
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _logout() async {
    final l10n = context.l10n;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.text('logout'), style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(l10n.text('logout_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.text('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: Text(l10n.text('logout'))),
        ],
      ),
    );
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => AuthScreen(role: widget.role)), (route) => false);
    }
  }

  void _showEditProfileDialog(Map<String, dynamic> currentData) {
    final nameCtrl = TextEditingController(text: currentData['name'] ?? '');
    final phoneCtrl = TextEditingController(text: currentData['phone'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 16),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _goToHome() {
    Widget destination;
    if (widget.role == 'SuperAdmin') {
      destination = const SuperAdminDashboardPage();
    } else if (widget.role == 'Admin') {
      destination = const AdminDashboardPage();
    } else {
      destination = const UserDashboard();
    }
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => destination), (route) => false);
  }

  String _resolveAddress(Map<String, dynamic> data) {
    final full = data['fullAddress']?.toString() ?? '';
    if (full.isNotEmpty) return full;
    
    final city = data['city']?.toString() ?? '';
    final landmark = data['landmark']?.toString() ?? '';
    if (city.isNotEmpty && landmark.isNotEmpty) return '$landmark, $city';
    if (city.isNotEmpty) return city;
    return 'No address saved';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAnyAdmin = widget.role == 'Admin' || widget.role == 'SuperAdmin';

    return AppShell(
      backgroundImage: 'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?q=80&w=2070&auto=format&fit=crop',
      overlayOpacity: 0.5,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: _loadProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF7BB960)));
              }

              final data = snapshot.data?.data() ?? <String, dynamic>{};
              final name = data['name']?.toString() ?? 'Farmer';
              final email = data['email']?.toString() ?? 'no-email@agro.com';
              final notificationsEnabled = data['notificationsEnabled'] as bool? ?? true;
              final locationEnabled = data['locationEnabled'] as bool? ?? !isAnyAdmin;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.filledTonal(onPressed: _goToHome, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1))),
                        Row(
                          children: [
                            IconButton.filledTonal(onPressed: () => _showEditProfileDialog(data), icon: const Icon(Icons.edit_rounded, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1))),
                            const SizedBox(width: 8),
                            const LanguageSelector(),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    AppGlassCard(
                      color: Colors.white.withOpacity(0.1),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: const Color(0xFF7BB960),
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'F', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                                Text(email, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _sectionHeading(l10n.text('account_overview')),
                    const SizedBox(height: 14),
                    _infoTile(Icons.badge_rounded, l10n.text('account_role'), widget.role),
                    const SizedBox(height: 12),
                    _addressTile(l10n, data),
                    const SizedBox(height: 30),
                    _sectionHeading(l10n.text('settings')),
                    const SizedBox(height: 14),
                    _settingTile(
                      Icons.notifications_rounded,
                      l10n.text('notifications'),
                      Switch(
                        value: notificationsEnabled,
                        onChanged: (val) => _updateSetting('notificationsEnabled', val).then((_) => setState(() {})),
                        activeColor: const Color(0xFF7BB960),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _settingTile(
                      Icons.location_on_rounded,
                      l10n.text('location_access'),
                      Switch(
                        value: locationEnabled,
                        onChanged: (val) => _updateSetting('locationEnabled', val).then((_) => setState(() {})),
                        activeColor: const Color(0xFF7BB960),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(l10n.text('logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white12), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _addressTile(dynamic l10n, Map<String, dynamic> data) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      color: Colors.white.withOpacity(0.08),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: const Color(0xFF7BB960)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Primary Address', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                Text(_resolveAddress(data), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            onPressed: _fetchingLocation ? null : _fetchAndSaveCurrentLocation,
            icon: _fetchingLocation 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.my_location_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title) {
    return Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white));
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      color: Colors.white.withOpacity(0.08),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7BB960)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile(IconData icon, String title, Widget trailing) {
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withOpacity(0.08),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7BB960)),
          const SizedBox(width: 14),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}
