import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import '../widgets/language_selector.dart';
import 'auth_screen.dart';
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
    this.variants = const [],
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
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

class _RevolveAgroProductsState extends State<RevolveAgroProducts> with TickerProviderStateMixin {
  late final AnimationController _listController;

  static const List<_CategoryData> _categories = [
    _CategoryData('bio_fertilizers', Icons.spa_outlined, Color(0xFFE6F2DC), 'Natural microbial solutions to boost soil health and root growth.'),
    _CategoryData('micronutrients', Icons.water_drop_outlined, Color(0xFFF7E9CC), 'Essential minerals for complete crop nutrition and disease resistance.'),
    _CategoryData('crop_boosters', Icons.bolt_outlined, Color(0xFFE5EEF8), 'Powerful growth stimulants for maximum yield and flowering.'),
    _CategoryData('soil_care', Icons.landscape_outlined, Color(0xFFECE4D7), 'Advanced soil conditioners to maintain pH balance and texture.'),
  ];

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppShell(
      backgroundImage: 'https://images.unsplash.com/photo-1595855759920-86582396756a?q=80&w=1974&auto=format&fit=crop',
      overlayOpacity: 0.35,
      child: SafeArea(
        child: Column(
          children: [
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

                  if (snapshot.hasError) {
                    return _buildErrorState(l10n, snapshot.error.toString());
                  }

                  final products = snapshot.data!.docs
                      .map((doc) => Product.fromFirestore(doc))
                      .toList();

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAnimatedCategories(),
                              const SizedBox(height: 26),
                              Text(
                                l10n.text('featured_products'),
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF183020)),
                              ),
                              const SizedBox(height: 18),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        sliver: SliverList.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final anim = CurvedAnimation(
                              parent: _listController,
                              curve: Interval((index / (products.isNotEmpty ? products.length : 1)).clamp(0, 1), 1.0, curve: Curves.easeOut),
                            );
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _ProductCreativeCard(product: products[index]),
                                ),
                              ),
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
    );
  }

  Widget _buildAnimatedCategories() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final anim = CurvedAnimation(
            parent: _listController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          );
          return ScaleTransition(
            scale: anim,
            child: _CategoryCreativeCard(category: _categories[index]),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF183020)),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.5)),
          ),
          const Spacer(),
          const LanguageSelector(),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserGalleryScreen())),
            icon: const Icon(Icons.photo_library_outlined, color: Color(0xFF183020)),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic l10n, String error) {
    return Center(
      child: AppEmptyState(
        icon: Icons.error_outline_rounded,
        title: l10n.text('auth_failed'),
        subtitle: error,
      ),
    );
  }
}

class _ProductCreativeCard extends StatefulWidget {
  final Product product;
  const _ProductCreativeCard({required this.product});

  @override
  State<_ProductCreativeCard> createState() => _ProductCreativeCardState();
}

class _ProductCreativeCardState extends State<_ProductCreativeCard> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
     onTap: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProductDetailsPage(
      product: {
        'name': widget.product.name,
        'description': widget.product.description,
        'imageUrl': widget.product.imageUrl,
        'price': widget.product.price,
        'variants': widget.product.variants,
      },
      productId: widget.product.id ?? '',
      role: 'User', // change to Vendor if needed
    ),
  ),
), 
      child: AppGlassCard(
        padding: EdgeInsets.zero,
        color: Colors.white.withOpacity(0.85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: widget.product.name,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: Image.network(widget.product.imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  right: 16, top: 16,
                  child: GestureDetector(
                    onTap: () => setState(() => _isLiked = !_isLiked),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isLiked ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isLiked ? Colors.red : const Color(0xFF183020),
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16, bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF2F6A3E), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      widget.product.price <= 0 ? 'Request Quote' : '₹${widget.product.price}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(widget.product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF183020))),
                      ),
                      const Icon(Icons.park_rounded, color: Color(0xFF7BB960), size: 24),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(widget.product.details, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2F6A3E), fontSize: 14)),
                  const SizedBox(height: 12),
                  Text(widget.product.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF424242), height: 1.4)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFFD9952E), size: 18),
                      const SizedBox(width: 8),
                      const Text('High Performance', style: TextStyle(color: Color(0xFFD9952E), fontWeight: FontWeight.bold, fontSize: 13)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_rounded, color: Color(0xFF183020), size: 20),
                    ],
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

class _CategoryCreativeCard extends StatelessWidget {
  final _CategoryData category;
  const _CategoryCreativeCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _CategoryGuideScreen(category: category),
          ),
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: category.tint.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
              child: Icon(category.icon, color: const Color(0xFF183020), size: 24),
            ),
            const Spacer(),
            Text(
              context.l10n.text(category.label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF183020), fontSize: 14),
            ),
            const Text('Explore', style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _CategoryData {
  final String label;
  final IconData icon;
  final Color tint;
  final String description;
  const _CategoryData(this.label, this.icon, this.tint, this.description);
}

// --- NEW CATEGORY GUIDE SCREEN ---

class _CategoryGuideScreen extends StatelessWidget {
  final _CategoryData category;
  const _CategoryGuideScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppShell(
      backgroundImage: 'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?q=80&w=2070&auto=format&fit=crop',
      overlayOpacity: 0.5,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(l10n.text(category.label), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              AppGlassCard(
                color: Colors.white.withOpacity(0.15),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: category.tint.withOpacity(0.3), shape: BoxShape.circle),
                      child: Icon(category.icon, size: 64, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.text(category.label),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      category.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildDetailItem(Icons.verified_rounded, 'Certified Quality', 'All products in this category are tested for maximum efficacy.'),
              const SizedBox(height: 16),
              _buildDetailItem(Icons.eco_rounded, 'Eco Friendly', 'Sustainable solutions designed to protect the environment.'),
              const SizedBox(height: 16),
              _buildDetailItem(Icons.trending_up_rounded, 'Proven Results', 'Trusted by farmers across the region for higher crop yields.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String desc) {
    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      color: Colors.white.withOpacity(0.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7BB960), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}