
import 'package:flutter/material.dart';
import './marketplace_screen.dart';
import 'vendor_orders_page.dart';
import './profile_page.dart';

class VendorDashboard extends StatelessWidget {
  const VendorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vendor Dashboard")),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _card(context, "Browse Products", Icons.store, const MarketplaceScreen()),
          _card(context, "My Orders", Icons.shopping_cart, const VendorOrdersPage()),
          _card(context, "Profile", Icons.person, const ProfilePage(role: 'Vendor')),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, String title, IconData icon, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 10),
            Text(title),
          ],
        ),
      ),
    );
  }
}

