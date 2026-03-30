import 'package:flutter/material.dart';

import 'fertilizer_guide_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            colors: [
              Color(0xFFEAF3DE),
              Color(0xFFF7F3E8),
            ],
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD9952E), Color(0xFFE8B154)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sunny_snowing, color: Colors.white, size: 34),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "Recommended this week for crop nutrition and root-strength support.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
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
                      _buildProductCard(
                        name: "REVO MICRO MIX",
                        description: "Mix Micronutrient Liquid",
                        price: "Rs.1500/=",
                        imageColor: const Color(0xFFE2EEF6),
                      ),
                      _buildProductCard(
                        name: "REVO POTASH",
                        description: "Potash Derived From Rhodophytes",
                        price: "Rs.800/=",
                        imageColor: const Color(0xFFF7E5CF),
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

  Widget _buildProductCard({
    required String name,
    required String description,
    required String price,
    required Color imageColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: imageColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.eco_rounded, color: Color(0xFF2F6A3E), size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF183020),
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 10),
                Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFF2F6A3E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2DF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2F6A3E)),
            ),
          ),
        ],
      ),
    );
  }
}
