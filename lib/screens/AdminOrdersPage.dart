import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // REQUIRED for logout
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Floating Logout Button correctly integrated
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            // Clears navigation stack and goes back to login
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        backgroundColor: Colors.black87,
        icon: const Icon(Icons.power_settings_new, color: Colors.white),
        label: const Text("Admin Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: Column(
        children: [
          // 1. Header with Background Image and Admin Icon
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://revolveagro.com/wp-content/uploads/2023/03/hero-bg.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 50,
                right: 20,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_pin, size: 45, color: Colors.grey[700]),
                ),
              ),
              const Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "Orders",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
              Positioned(
                top: 50,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            ],
          ),

          // 2. Orders List from Firestore
          Expanded(
            child: Container(
              color: const Color(0xFFF9F8F3),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No orders found."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 80), // bottom padding for FAB
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var order = snapshot.data!.docs[index];

                      return _orderCard(
                        userName: order['userName'] ?? "User",
                        products: order['products'] as List<dynamic>,
                        totalAmount: order['totalAmount'].toString(),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // 3. Bottom Navigation Bar
          _bottomNavBar(),
        ],
      ),
    );
  }

  Widget _orderCard({
    required String userName,
    required List<dynamic> products,
    required String totalAmount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, size: 20, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              const Icon(Icons.phone, size: 18, color: Colors.green),
            ],
          ),
          const Divider(height: 25),

          ...products.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['imageUrl'] ?? "https://via.placeholder.com/150",
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 50, width: 50, color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['productName'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "Quantity: ${item['quantity']}",
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),

          const Divider(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Received:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              Text(
                "Rs.$totalAmount/=",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.home_outlined, size: 30), onPressed: () {}),
          IconButton(icon: const Icon(Icons.menu, size: 30), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_outline, size: 30), onPressed: () {}),
          IconButton(icon: const Icon(Icons.logout_rounded, size: 30), onPressed: () {}),
        ],
      ),
    );
  }
}