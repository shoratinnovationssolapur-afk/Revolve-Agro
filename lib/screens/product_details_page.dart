import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import 'payment_page.dart';
import 'product_list.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;
  final int unitPrice = 1500;

  Future<void> _showPopup({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.text('ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBuyNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await _showPopup(
        title: context.l10n.text('login_required'),
        message: context.l10n.text('login_buy_product'),
      );
      return;
    }

    final totalAmount = unitPrice * quantity;
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          cartItems: [
            {
              'productName': widget.product.name,
              'quantity': quantity,
            }
          ],
          totalAmount: totalAmount,
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await _showPopup(
        title: context.l10n.text('login_required'),
        message: context.l10n.text('login_add_to_cart'),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('cart').add({
        'userId': user.uid,
        'productName': widget.product.name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': unitPrice * quantity,
        'imageUrl': widget.product.imageUrl,
        'addedAt': FieldValue.serverTimestamp(),
        'status': 'in_cart',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.textWithArgs('added_to_cart', {'name': widget.product.name})),
            backgroundColor: const Color(0xFF2F6A3E),
            action: SnackBarAction(
              label: context.l10n.text('view_cart'),
              textColor: Colors.white,
              onPressed: () async {
                final cartSnapshot = await FirebaseFirestore.instance
                    .collection('cart')
                    .where('userId', isEqualTo: user.uid)
                    .get();

                final items = <Map<String, dynamic>>[];
                var total = 0;

                for (final doc in cartSnapshot.docs) {
                  items.add({
                    'productName': doc['productName'],
                    'quantity': doc['quantity'],
                  });
                  total += (doc['totalPrice'] as num).toInt();
                }

                if (mounted) {
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
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.textWithArgs('failed_add_to_cart', {'error': '$e'})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showZoomedImage(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 48,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalAmount = unitPrice * quantity;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDDEBD0),
              Color(0xFFF7F3E8),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      SizedBox(
                        height: constraints.maxHeight * 0.44,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () => _showZoomedImage(context),
                                child: Hero(
                                  tag: widget.product.name,
                                  child: Image.network(
                                    widget.product.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFE7E0D3),
                                      child: const Icon(Icons.image_not_supported_outlined, size: 52),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.15),
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.42),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 16,
                              child: IconButton.filledTonal(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                            ),
                            Positioned(
                              left: 20,
                              right: 20,
                              bottom: 18,
                              child: IgnorePointer(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      child: Text(
                                        l10n.text('tap_image_to_zoom'),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      widget.product.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7F3E8),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _InfoPill(label: widget.product.details, icon: Icons.eco_outlined),
                                _InfoPill(label: l10n.text('premium_crop_care'), icon: Icons.workspace_premium_outlined),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              widget.product.description,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.55,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Wrap(
                                runSpacing: 16,
                                spacing: 16,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SizedBox(
                                    width: constraints.maxWidth > 430 ? constraints.maxWidth * 0.42 : constraints.maxWidth,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.text('estimated_price'),
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Rs.$totalAmount/=",
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF183020),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE9F2DF),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _quantityBtn(Icons.remove_rounded, () {
                                          if (quantity > 1) {
                                            setState(() => quantity--);
                                          }
                                        }),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            quantity.toString().padLeft(2, '0'),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        _quantityBtn(Icons.add_rounded, () => setState(() => quantity++)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: constraints.maxWidth > 460
                                      ? (constraints.maxWidth - 60) / 2
                                      : double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _handleBuyNow,
                                    icon: const Icon(Icons.flash_on_rounded),
                                    label: Text(l10n.text('buy_now')),
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 460
                                      ? (constraints.maxWidth - 60) / 2
                                      : double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _addToCart,
                                    icon: const Icon(Icons.shopping_bag_outlined),
                                    label: Text(l10n.text('add_to_cart')),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _quantityBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 40,
          width: 40,
          child: Icon(icon, color: const Color(0xFF214B2D)),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoPill({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2F6A3E)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF214B2D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
