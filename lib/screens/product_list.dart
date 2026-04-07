import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
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
  final List<Map<String, dynamic>> variants;

  Product({
    this.id,
    required this.name,
    required this.details,
    required this.description,
    required this.imageUrl,
    this.price = 0,
    this.inventoryQuantity = 999999,
    this.variants = const [], // 🔥 ADD THIS INITIALIZER
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // 🔥 This function ensures numbers are always Ints for Android
    int toInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Product(
      id: doc.id,
      name: data['name']?.toString() ?? 'Unnamed',
      details: data['details']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      price: toInt(data['price']),
      inventoryQuantity: toInt(data['inventoryQuantity']),

      // 🔥 The "Android Fix": Force-cast each item in the list
      variants: (data['variants'] as List<dynamic>?)?.map((v) {
        final Map<dynamic, dynamic> vMap = v as Map<dynamic, dynamic>;
        return {
          'packingSize': vMap['packingSize']?.toString() ?? '',
          'drpPrice': toInt(vMap['drpPrice']),
          'mrpPrice': toInt(vMap['mrpPrice']),
        };
      }).toList() ?? [],
    );
  }
}

class RevolveAgroProducts extends StatefulWidget {
  const RevolveAgroProducts({super.key});

  @override
  State<RevolveAgroProducts> createState() => _RevolveAgroProductsState();
}

class _RevolveAgroProductsState extends State<RevolveAgroProducts> {
  // 🔥 Integrated Categories and Benefits from HEAD
  static const List<_CategoryData> _categories = [
    _CategoryData('bio_fertilizers', Icons.spa_outlined, Color(0xFFE6F2DC)),
    _CategoryData('micronutrients', Icons.water_drop_outlined, Color(0xFFF7E9CC)),
    _CategoryData('crop_boosters', Icons.bolt_outlined, Color(0xFFE5EEF8)),
    _CategoryData('soil_care', Icons.landscape_outlined, Color(0xFFECE4D7)),
  ];

  static const List<_ShopBenefit> _benefits = [
    _ShopBenefit(
      title: 'trusted_agri_products',
      subtitle: 'trusted_agri_products_subtitle',
      icon: Icons.verified_outlined,
    ),
    _ShopBenefit(
      title: 'farmer_friendly_flow',
      subtitle: 'farmer_friendly_flow_subtitle',
      icon: Icons.mobile_friendly_outlined,
    ),
    _ShopBenefit(
      title: 'built_for_repeat_buying',
      subtitle: 'built_for_repeat_buying_subtitle',
      icon: Icons.repeat_outlined,
    ),
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
        label: Text(l10n.text('view_cart') ?? "View Cart"),
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
              // 🔥 Integrated Dynamic Header
              _buildHeader(context, l10n),

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

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(l10n.text('no_products_found') ?? "No products available"),
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
                                const SizedBox(height: 18),
                                // Category List from HEAD
                                SizedBox(
                                  height: 132,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _categories.length,
                                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                                    itemBuilder: (context, index) => _CategoryCard(category: _categories[index]),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                // Benefits Section
                                ..._benefits.map((b) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _BenefitCard(benefit: b),
                                )),
                                const SizedBox(height: 22),
                                Text(
                                  l10n.text('featured_products'),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF183020)),
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
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _ProductCard(product: products[index]),
                            ),
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
      child: Row(
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
    );
  }

  Future<void> _openCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.text('please_login_view_cart'))));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFD9952E))),
    );

    try {
      final cartSnapshot = await FirebaseFirestore.instance.collection('cart').where('userId', isEqualTo: user.uid).get();
      if (context.mounted) Navigator.pop(context);

      if (cartSnapshot.docs.isEmpty) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.text('no_items_added_cart'))));
        return;
      }

      final items = cartSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'productName': data['productName'],
          'productId': data['productId']?.toString(),
          'quantity': (data['quantity'] as num).toInt(),
          'unitPrice': (data['unitPrice'] as num).toInt(),
          'totalPrice': (data['totalPrice'] as num).toInt(),
          'imageUrl': data['imageUrl']?.toString(),
        };
      }).toList();

      final total = items.fold<int>(0, (sum, item) => sum + (item['totalPrice'] as int));

      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentPage(cartItems: items, totalAmount: total)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
                  Hero(tag: product.name, child: Image.network(product.imageUrl, height: 220, width: double.infinity, fit: BoxFit.cover)),
                  Positioned(
                    left: 16, top: 16,
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
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF183020))),
                  const SizedBox(height: 6),
                  Text(product.details, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2F6A3E))),
                  const SizedBox(height: 10),
                  Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, height: 1.45)),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmall = constraints.maxWidth < 360;
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsPage(product: product))),
                              child: Text(context.l10n.text('view_details'), style: TextStyle(fontSize: isSmall ? 12 : 14)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 52, width: isSmall ? 44 : 52,
                            decoration: BoxDecoration(color: const Color(0xFFE8F2DF), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2F6A3E)),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helper UI Classes (From HEAD) ---

class _CategoryCard extends StatelessWidget {
  final _CategoryData category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: category.tint, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44, width: 44,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(14)),
            child: Icon(category.icon, color: const Color(0xFF214B2D)),
          ),
          const Spacer(),
          Text(context.l10n.text(category.label), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF183020))),
          const SizedBox(height: 4),
          Text(context.l10n.text('browse_solutions'), style: const TextStyle(color: Color(0xFF496155), fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final _ShopBenefit benefit;
  const _BenefitCard({required this.benefit});

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46, width: 46,
            decoration: BoxDecoration(color: const Color(0xFFE7F1D9), borderRadius: BorderRadius.circular(14)),
            child: Icon(benefit.icon, color: const Color(0xFF2F6A3E)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.text(benefit.title), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF183020))),
                const SizedBox(height: 6),
                Text(context.l10n.text(benefit.subtitle), style: TextStyle(color: Colors.grey.shade700, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  final String label;
  final IconData icon;
  final Color tint;
  const _CategoryData(this.label, this.icon, this.tint);
}

class _ShopBenefit {
  final String title;
  final String subtitle;
  final IconData icon;
  const _ShopBenefit({required this.title, required this.subtitle, required this.icon});
}