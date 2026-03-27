import 'package:flutter/material.dart';
import 'auth_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light background for contrast
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Makes children full-width
            children: [
              // Branding / Header
              const Icon(Icons.eco, size: 60, color: Colors.green),
              const SizedBox(height: 10),
              const Text(
                "Choose Your Role",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                "English | Marathi", // Updated to match your site's languages
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 50),

              // USER CARD (Farmer/Dealer)
              _buildRoleCard(
                context,
                title: "Login as User",
                subtitle: "Browse products and get expert advice",
                icon: Icons.person,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen(role: "User")),
                ),
              ),

              const SizedBox(height: 20),

              // ADMIN CARD
              _buildRoleCard(
                context,
                title: "Login as Admin",
                subtitle: "Manage inventory and enquiries",
                icon: Icons.admin_panel_settings,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen(role: "Admin")),
                ),
              ),

              const SizedBox(height: 50),
              const Text(
                "We're popular in the agriculture\nmarket globally",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell( // Added InkWell for a nice ripple effect when clicking
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // Use rounded rects instead of circles
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row( // Changed to Row to use full screen width effectively
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: Colors.green),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}