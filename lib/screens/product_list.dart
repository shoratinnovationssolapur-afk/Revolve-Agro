import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/language_selector.dart';
import 'payment_page.dart';
import 'profile_page.dart';
import 'product_details_page.dart';
import 'welcome_screen.dart';
import 'user_gallery_screen.dart';

class Product {
  final String? id;
  final String name;
  final String details;
  final String description;
  final String imageUrl;
  final int price;
  final int inventoryQuantity;

  Product({
    this.id,
    required this.name,
    required this.details,
    required this.description,
    required this.imageUrl,
    this.price = 0,
    this.inventoryQuantity = 999999,
  });

  // Factory to create Product from Firestore Document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safely parse numbers (handles both String and int/double from Firestore)
    int parseNumber(dynamic value, int defaultValue) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return Product(
      id: doc.id,
      name: data['name']?.toString() ?? 'Unnamed Product',
      details: data['details']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? 'https://via.placeholder.com/800x500',
      price: parseNumber(data['price'], 1500),
      inventoryQuantity: parseNumber(data['inventoryQuantity'], 999),
    );
  }
}

class RevolveAgroProducts extends StatefulWidget {
  const RevolveAgroProducts({super.key});

  @override
  State<RevolveAgroProducts> createState() => _RevolveAgroProductsState();
}

class _RevolveAgroProductsState extends State<RevolveAgroProducts> {
  final List<String> _highlights = const [
    'Soil Health',
    'Fast Delivery',
    'Crop Nutrition',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCart(context),
        backgroundColor: const Color(0xFFD9952E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shopping_cart_checkout_rounded),
        label: const Text("View Cart"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE7F0DB), Color(0xFFF7F3E8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔥 HEADER SECTION (Static)
              _buildHeader(context, l10n),

              // 🔥 PRODUCT LIST SECTION (Real-time Stream)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .orderBy('updatedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF2F6A3E)));
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(l10n.text('no_products_found') ?? "No products available"),
                          ],
                        ),
                      );
                    }

                    final products = snapshot.data!.docs
                        .map((doc) => Product.fromFirestore(doc))
                        .toList();

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                Text(
                                  l10n.text('featured_products'),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF183020)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "${products.length} ${l10n.text('products_ready')}",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 18),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                          sliver: SliverList.builder(
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _ProductCard(product: products[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen(preferredRole: 'User')),
                      (route) => false,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage(role: 'User'))),
                icon: const Icon(Icons.person_outline_rounded),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserGalleryScreen())),
                icon: const Icon(Icons.photo_library_outlined),
              ),
              const SizedBox(width: 6),
              const LanguageSelector(),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF2F6A3E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.text('fast_farm_delivery'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2F6A3E), Color(0xFF6CAA58)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(34),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.text('smart_crop_title'),
                  style: const TextStyle(color: Colors.white, fontSize: 30, height: 1.08, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.text('smart_crop_subtitle'),
                  style: const TextStyle(color: Color(0xFFEAF5E3), height: 1.5),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _highlights.map((chip) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(30)),
                    child: Text(chip, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Cart logic remains the same (fetching from Firestore) ---
  Future<void> _openCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to view your cart")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFD9952E))),
    );

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (context.mounted) Navigator.pop(context);

      if (cartSnapshot.docs.isEmpty) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Your cart is empty")));
        return;
      }

      final items = <Map<String, dynamic>>[];
      var total = 0;

      for (final doc in cartSnapshot.docs) {
        final data = doc.data();
        final int qty = (data['quantity'] as num).toInt();
        final int unitPrice = (data['unitPrice'] ?? 0) is num
            ? (data['unitPrice'] as num).toInt()
            : int.tryParse((data['unitPrice'] ?? '0').toString()) ?? 0;
        final int totalPrice = (data['totalPrice'] ?? 0) is num
            ? (data['totalPrice'] as num).toInt()
            : unitPrice * qty;

        items.add({
          'productName': doc['productName'],
          'productId': data['productId']?.toString(),
          'quantity': qty,
          'unitPrice': unitPrice,
          'totalPrice': totalPrice,
          'imageUrl': data['imageUrl']?.toString(),
        });
        total += totalPrice;
      }

      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentPage(cartItems: items, totalAmount: total)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching cart: $e")));
      }
    }
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsPage(product: product))),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 22, offset: const Offset(0, 12))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Stack(
                  children: [
                    Hero(
                      tag: product.name,
                      child: Image.network(
                        product.imageUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 220,
                          color: const Color(0xFFE5E0D4),
                          child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 48)),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(30)),
                        child: Text(
                          product.price <= 0 ? 'Request Quote' : 'Rs.${product.price}/=',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF214B2D)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF183020))),
                    const SizedBox(height: 6),
                    Text(product.details, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2F6A3E))),
                    const SizedBox(height: 10),
                    Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, height: 1.45)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsPage(product: product))),
                            child: Text(context.l10n.text('view_details')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(color: const Color(0xFFE8F2DF), borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2F6A3E)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}