import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'product_list.dart';
import 'product_details_page.dart';
import 'profile_page.dart';
import 'payment_page.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0;

  String userName = "";
  String location = "India";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ✅ LOAD USER NAME
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        userName = doc.data()?['name'] ?? "User";
      });
    }
  }

  // ✅ HOME SCREEN (MAIN DASHBOARD)
  Widget _buildHome() {
    return SafeArea(
      child: Column(
        children: [
          // 🔝 TOP SECTION
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // NAME + LOCATION
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(location),
                    const Spacer(),
                    Text(
                      "Hi, $userName 👋",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 🔍 SEARCH BAR
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 📸 GALLERY FROM FIRESTORE
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('gallery')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!.docs;

                if (items.isEmpty) {
                  return const Center(child: Text("No gallery items yet"));
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final data = items[index];

                    final imageUrl = data['imageUrl'];
                    final productName = data['productName'];
                    final description = data['description'];

                    return Card(
                      margin: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // IMAGE
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              imageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // DETAILS
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(description),

                                const SizedBox(height: 12),

                                // 🔥 VIEW PRODUCT BUTTON
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsPage(
                                          product: Product(
                                            name: productName,
                                            details: "",
                                            description: description,
                                            imageUrl: imageUrl,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("View Product"),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🛒 CART PAGE (REUSE)
  Widget _buildCart() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPage(
                cartItems: const [],
                totalAmount: 0,
              ),
            ),
          );
        },
        child: const Text("Go to Cart"),
      ),
    );
  }

  // 📦 PRODUCT PAGE
  Widget _buildProducts() {
    return RevolveAgroProducts();
  }

  // 👤 PROFILE
  Widget _buildProfile() {
    return const ProfilePage(role: "User");
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHome(),
      _buildProducts(),
      _buildCart(),
      _buildProfile(),
    ];

    return Scaffold(
      body: pages[_currentIndex],

      // 🔥 BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF2F6A3E),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture),
            label: "Products",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Cart",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}