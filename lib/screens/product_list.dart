import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

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

  Product({
    this.id,
    required this.name,
    required this.details,
    required this.description,
    required this.imageUrl,
    this.price = 0,
    this.inventoryQuantity = 999999,
  });
}

class RevolveAgroProducts extends StatefulWidget {
  const RevolveAgroProducts({super.key});

  @override
  State<RevolveAgroProducts> createState() => _RevolveAgroProductsState();
}

class _RevolveAgroProductsState extends State<RevolveAgroProducts> {
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

  static final List<Product> _fallbackProducts = [
    Product(
      name: 'revo_rhizal_name',
      details: 'revo_rhizal_details',
      description: 'revo_rhizal_description',
      imageUrl: 'https://via.placeholder.com/800x500?text=REVO+RHIZAL',
      price: 2400,
      inventoryQuantity: 999999,
    ),
    Product(
      name: 'revo_micro_mix_name',
      details: 'revo_micro_mix_details',
      description: 'revo_micro_mix_description',
      imageUrl: 'https://via.placeholder.com/800x500?text=REVO+MICRO+MIX',
      price: 1500,
      inventoryQuantity: 999999,
    ),
    Product(
      name: 'revo_potash_name',
      details: 'revo_potash_details',
      description: 'revo_potash_description',
      imageUrl: 'https://via.placeholder.com/800x500?text=REVO+POTASH',
      price: 800,
      inventoryQuantity: 999999,
    ),
  ];

  List<Product> _localizedFallbackProducts(BuildContext context) {
    final l10n = context.l10n;
    return _fallbackProducts
        .map(
          (product) => Product(
            name: l10n.text(product.name),
            details: l10n.text(product.details),
            description: l10n.text(product.description),
            imageUrl: product.imageUrl,
            price: product.price,
          ),
        )
        .toList();
  }

  Future<List<Product>> fetchProducts() async {
    try {
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('updatedAt', descending: true)
          .get();

      if (productsSnapshot.docs.isNotEmpty) {
        return productsSnapshot.docs.map((doc) {
          final data = doc.data();

          final priceRaw = data['price'];
          final invRaw = data['inventoryQuantity'];

          final price = priceRaw is num
              ? priceRaw.toInt()
              : int.tryParse((priceRaw ?? 1500).toString()) ?? 1500;

          final inventoryQuantity = invRaw is num
              ? invRaw.toInt()
              : int.tryParse((invRaw ?? 999999).toString()) ?? 999999;

          return Product(
            id: doc.id,
            name: (data['name'] ?? '').toString(),
            details: (data['details'] ?? '').toString(),
            description: (data['description'] ?? '').toString(),
            imageUrl: (data['imageUrl'] ?? '').toString(),
            price: price,
            inventoryQuantity: inventoryQuantity,
          );
        }).toList();
      }
    } catch (_) {
      // If Firestore isn't available for some reason, fall back to scrape.
    }

    if (kIsWeb) {
      return _fallbackProducts;
    }

    const url = 'https://revolveagro.com';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final productElements = document.querySelectorAll('.product');

        if (productElements.isEmpty) {
          return _fallbackProducts;
        }

        return productElements.map((element) {
          return Product(
            name: element.querySelector('h3')?.text.trim() ??
                'Unknown Product',
            details: element.querySelector('.product-details')?.text.trim() ??
                '',
            description:
                element.querySelector('.product-description')?.text.trim() ?? '',
            imageUrl:
                '$url/${element.querySelector('img')?.attributes['src'] ?? ''}',
            // Scraped data doesn't include price/inventory; provide safe defaults.
            price: 1500,
            inventoryQuantity: 999999,
          );
        }).toList();
      }
    } catch (_) {}

    return _fallbackProducts;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: AppShell(
        child: SafeArea(
          child: FutureBuilder<List<Product>>(
            future: fetchProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2F6A3E)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text("${snapshot.error}", textAlign: TextAlign.center),
                  ),
                );
              }

              final rawProducts = snapshot.data;
              final products = rawProducts == null || identical(rawProducts, _fallbackProducts)
                  ? _localizedFallbackProducts(context)
                  : rawProducts;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppPageHeader(
                            title: l10n.text('agri_shop'),
                            subtitle: l10n.text('agri_shop_subtitle'),
                            badgeIcon: Icons.storefront_outlined,
                            leading: IconButton.filledTonal(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WelcomeScreen(preferredRole: 'User'),
                                  ),
                                  (route) => false,
                                );
                              },
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            actions: [
                              IconButton.filledTonal(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProfilePage(role: 'User'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_outline_rounded),
                              ),
                              const SizedBox(width: 6),
                              IconButton.filledTonal(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const UserGalleryScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.photo_library_outlined),
                              ),
                              const SizedBox(width: 6),
                              const LanguageSelector(),
                            ],
                          ),
                          const SizedBox(height: 18),
                          AppGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppPill(
                                        label: l10n.text('farmer_first_shopping'),
                                        icon: Icons.agriculture_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      l10n.text('fast_farm_delivery'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2F6A3E),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.text('smart_crop_title'),
                                  style: const TextStyle(
                                    color: Color(0xFF183020),
                                    fontSize: 30,
                                    height: 1.08,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  l10n.text('smart_crop_subtitle'),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 122,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _categories.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final category = _categories[index];
                                      return _CategoryCard(category: category);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          AppSectionHeading(
                            title: l10n.text('why_farmers_like_shop'),
                            subtitle: l10n.text('why_farmers_like_shop_subtitle'),
                          ),
                          const SizedBox(height: 14),
                          ..._benefits.map(
                            (benefit) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BenefitCard(benefit: benefit),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.text('featured_products'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF183020),
                            ),
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
                        final product = products[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _ProductCard(product: product),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('please_login_view_cart'))),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFD9952E)),
      ),
    );

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: user.uid)
          .get();

      Navigator.pop(context);

      if (cartSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.text('no_items_added_cart'))),
        );
        return;
      }

      final items = <Map<String, dynamic>>[];
      var total = 0;

      for (final doc in cartSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPage(
              cartItems: items,
              totalAmount: total,
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.textWithArgs('error_fetching_cart', {'error': '$e'}))),
      );
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductDetailsPage(product: product)),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
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
                          child: const Center(
                            child: Icon(Icons.image_not_supported_outlined, size: 48),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          product.price <= 0 ? 'Request Quote' : 'Rs.${product.price}/=',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF214B2D),
                          ),
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
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF183020),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.details,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F6A3E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsPage(product: product),
                                ),
                              );
                            },
                            child: Text(context.l10n.text('view_details')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2DF),
                            borderRadius: BorderRadius.circular(16),
                          ),
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

class _CategoryCard extends StatelessWidget {
  final _CategoryData category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: category.tint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(category.icon, color: const Color(0xFF214B2D)),
          ),
          const Spacer(),
          Text(
            context.l10n.text(category.label),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF183020),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.text('browse_solutions'),
            style: const TextStyle(
              color: Color(0xFF496155),
              fontSize: 12.5,
            ),
          ),
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
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1D9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(benefit.icon, color: const Color(0xFF2F6A3E)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text(benefit.title),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183020),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.text(benefit.subtitle),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.45,
                  ),
                ),
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

  const _ShopBenefit({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
