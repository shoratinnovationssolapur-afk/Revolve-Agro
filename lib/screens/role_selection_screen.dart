import 'package:flutter/material.dart';
import 'auth_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Choose Language", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // [cite: 28]
              const Text("English | Sinhala", style: TextStyle(color: Colors.grey)), // [cite: 28]
              const SizedBox(height: 40),

              // Farmer Card with Navigation
              _buildRoleCard(
                context,
                title: "Farmer", //
                icon: Icons.person_outline,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen(role: "Farmer"))
                ),
              ),

              const SizedBox(height: 20),

              // Dealer Card with Navigation
              _buildRoleCard(
                context,
                title: "Dealer", //
                icon: Icons.store_mall_directory_outlined,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen(role: "Dealer"))
                ),
              ),

              const SizedBox(height: 40),
              const Text(
                "We're popular in agriculture\nmarket globally", // [cite: 31]
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated helper with onTap parameter
  Widget _buildRoleCard(BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap, // Added this callback
  }) {
    return GestureDetector(
      onTap: onTap, // Triggers navigation when clicked
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 50, color: Colors.green),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}