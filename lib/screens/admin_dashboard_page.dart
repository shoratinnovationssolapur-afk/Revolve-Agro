import 'package:flutter/material.dart';
import 'admin_manage_products_page.dart';
import 'admin_orders_page.dart';
import '../widgets/language_selector.dart';
import 'welcome_screen.dart';
import 'admin_gallery_screen.dart'; // ✅ Added
import 'profile_page.dart'; // ✅ Added

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF3DE),
              Color(0xFFF7F3E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔥 HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF183020), Color(0xFF30523B)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const WelcomeScreen(preferredRole: 'Admin'),
                            ),
                                (route) => false,
                          );
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const LanguageSelector(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 🔥 DASHBOARD CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. MANAGE MEMBERS

                        // 2. VIEW ORDERS
                        _menuButton(
                          context,
                          label: 'View Orders',
                          icon: Icons.inbox_rounded,
                          color: const Color(0xFF2F6A3E),
                          destination: const AdminOrdersPage(),
                        ),

                        // 3. MANAGE PRODUCTS
                        _menuButton(
                          context,
                          label: 'Manage Products',
                          icon: Icons.inventory_2_rounded,
                          color: const Color(0xFFD9952E),
                          destination: const AdminManageProductsPage(),
                        ),

                        // 4. MANAGE GALLERY (New)
                        _menuButton(
                          context,
                          label: 'Manage Gallery',
                          icon: Icons.photo_library_rounded,
                          color: const Color(0xFF1E5631),
                          destination: const AdminGalleryScreen(),
                        ),

                        // 5. PROFILE SETTINGS (New)
                        _menuButton(
                          context,
                          label: 'Profile Settings',
                          icon: Icons.admin_panel_settings_rounded,
                          color: const Color(0xFF333333),
                          destination: const ProfilePage(role: 'Admin'),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Workspace for Revolve Agro management.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 30),
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

  // ✅ HELPER METHOD FOR MENU BUTTONS
  Widget _menuButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required Color color,
        required Widget destination,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}