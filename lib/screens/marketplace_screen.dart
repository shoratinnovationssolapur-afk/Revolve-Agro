import 'package:flutter/material.dart';
import 'fertilizer_guide_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // Inside MarketplaceScreen Scaffold
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FertilizerGuideScreen()),
          );
        },
        label: const Text("Fertilizer Guide"), // [cite: 146]
        icon: const Icon(Icons.menu_book),
        backgroundColor: Colors.green,
      ),
      appBar: AppBar(
        title: const Text("Marketplace"), //
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Featured Products", //
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildProductCard(
                  name: "REVO RHIZAL", // [cite: 57]
                  description: "Mycorrhizal Bio Fertilizer (100gm)", // [cite: 59]
                  price: "Rs.2400/=", // [cite: 60]
                  imageColor: Colors.green[100]!,
                ),
                _buildProductCard(
                  name: "REVO MICRO MIX", // [cite: 68]
                  description: "Mix Micronutrient Liquid", // [cite: 69]
                  price: "Rs.1500/=", // [cite: 70]
                  imageColor: Colors.blue[100]!,
                ),
                _buildProductCard(
                  name: "REVO POTASH", // [cite: 72]
                  description: "Potash Derived From Rhodophytes", // [cite: 75]
                  price: "Rs.800/=", // [cite: 75]
                  imageColor: Colors.orange[100]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required String name,
    required String description,
    required String price,
    required Color imageColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: imageColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco, color: Colors.green),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(price, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.yellow), // [cite: 62]
                shape: const StadiumBorder(),
              ),
              child: const Text("SHOP NOW", style: TextStyle(color: Colors.black, fontSize: 10)), // [cite: 62]
            ),
          ],
        ),
      ),
    );
  }
}