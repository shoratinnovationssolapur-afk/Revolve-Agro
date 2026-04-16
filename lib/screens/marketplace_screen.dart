import 'package:flutter/material.dart';

import 'fertilizer_guide_screen.dart';
import 'profile_page.dart';
import 'user_gallery_screen.dart';
import 'user_inquiries_page.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF183020)),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo),
                        title: const Text("View Gallery"),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserGalleryScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.history_edu_rounded),
                        title: const Text("Support History"),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserInquiriesPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text("Profile"),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(role: 'User'),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: const Text("Language"),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FertilizerGuideScreen()),
          );
        },
        backgroundColor: const Color(0xFF2F6A3E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.menu_book_outlined),
        label: const Text("Fertilizer Guide"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3DE), Color(0xFFF7F3E8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Marketplace",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183020),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Featured crop nutrition and bio-fertilizer solutions for a stronger season.",
                  style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFD9952E), Color(0xFFE8B154)]),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sunny_snowing, color: Colors.white, size: 34),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "Recommended this week for crop nutrition and root-strength support.",
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: ListView(
                    children: [
                      _buildProductCard(
                        name: "REVO RHIZAL",
                        description: "Mycorrhizal Bio Fertilizer (100gm)",
                        price: "Rs.2400/=",
                        imageColor: const Color(0xFFE6F2DD),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard({required String name, required String description, required String price, required Color imageColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Row(
        children: [
          Container(width: 84, height: 84, decoration: BoxDecoration(color: imageColor, borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.eco_rounded, color: Color(0xFF2F6A3E), size: 34)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), Text(description), Text(price, style: const TextStyle(color: Color(0xFF2F6A3E)))]))
        ],
      ),
    );
  }
}
