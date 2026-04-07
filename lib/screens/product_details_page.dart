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

  // 🔥 NEW: Selected Variant tracking
  Map<String, dynamic>? _selectedVariant;

  @override
  void initState() {
    super.initState();

    // 🔥 FIX: If variants list is empty, create a temporary one from old data
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    } else {
      // This handles all your existing products like Boro Glymax
      _selectedVariant = {
        'packingSize': 'Standard', // You can change this to '1 Ltr' if preferred
        'drpPrice': widget.product.price,
        'mrpPrice': widget.product.price, // Default MRP to DRP if missing
      };
    }
  }

  // Getters for dynamic pricing based on selection
// 🔥 FIX: Added clear null-checks and direct field mapping
  int get _currentDRP => (_selectedVariant?['drpPrice'] ?? 0).toInt();
  int get _currentMRP => (_selectedVariant?['mrpPrice'] ?? 0).toInt();
  String get _currentSize => _selectedVariant?['packingSize'] ?? 'N/A';

  Future<void> _showPopup({required String title, required String message}) async {
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
      await _showPopup(title: context.l10n.text('login_required'), message: context.l10n.text('login_buy_product'));
      return;
    }

    final totalAmount = _currentDRP * quantity;
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          cartItems: [
            {
              'productName': "${widget.product.name} ($_currentSize)",
              'quantity': quantity,
              'productId': widget.product.id,
              'unitPrice': _currentDRP,
              'totalPrice': totalAmount,
              'imageUrl': widget.product.imageUrl,
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
      await _showPopup(title: context.l10n.text('login_required'), message: context.l10n.text('login_add_to_cart'));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('cart').add({
        'userId': user.uid,
        'productId': widget.product.id,
        'productName': "${widget.product.name} ($_currentSize)",
        'quantity': quantity,
        'unitPrice': _currentDRP,
        'totalPrice': _currentDRP * quantity,
        'imageUrl': widget.product.imageUrl,
        'addedAt': FieldValue.serverTimestamp(),
        'status': 'in_cart',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${widget.product.name} ($_currentSize) added to cart!"),
            backgroundColor: const Color(0xFF2F6A3E),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
                child: Center(child: Image.network(widget.product.imageUrl, fit: BoxFit.contain)),
              ),
            ),
            Positioned(top: 48, right: 20, child: CircleAvatar(child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalAmount = _currentDRP * quantity;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDDEBD0), Color(0xFFF7F3E8)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Image Section
                    _buildHeroImage(constraints),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F3E8),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoPill(label: widget.product.details, icon: Icons.eco_outlined),
                          const SizedBox(height: 18),
                          Text(widget.product.description, style: TextStyle(fontSize: 15, height: 1.55, color: Colors.grey.shade800)),

                          const SizedBox(height: 24),
                          const Text("Select Packing Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),

                          // 🔥 NEW: Horizontal Variant Selection
                          _buildVariantSelector(),

                          const SizedBox(height: 24),

                          // 🔥 NEW: Price Card (MRP vs DRP)
                          _buildPriceCard(),

                          const SizedBox(height: 22),

                          // Quantity Selector
                          _buildQuantityAndTotal(totalAmount),

                          const SizedBox(height: 24),

                          // Action Buttons
                          _buildActionButtons(l10n),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(BoxConstraints constraints) {
    return SizedBox(
      height: constraints.maxHeight * 0.40,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _showZoomedImage(context),
              child: Hero(tag: widget.product.name, child: Image.network(widget.product.imageUrl, fit: BoxFit.cover)),
            ),
          ),
          Positioned(top: 12, left: 16, child: IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded))),
        ],
      ),
    );
  }

  Widget _buildVariantSelector() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.product.variants.length,
        itemBuilder: (context, index) {
          final variant = widget.product.variants[index];
          bool isSelected = _selectedVariant == variant;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(variant['packingSize']),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedVariant = variant),
              selectedColor: const Color(0xFF2F6A3E),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceCard() {
    // Calculate discount percentage to show the farmer the value
    final double discount = _currentMRP > 0
        ? ((_currentMRP - _currentDRP) / _currentMRP) * 100
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("MRP Price:", style: TextStyle(color: Colors.grey)),
              Row(
                children: [
                  Text(
                      "₹$_currentMRP",
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.redAccent,
                          fontSize: 16
                      )
                  ),
                  if (discount > 0) // Only show if there's an actual discount
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                      child: Text("${discount.toStringAsFixed(0)}% OFF", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Partner Price (DRP):", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("₹$_currentDRP", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF183020))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityAndTotal(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              _quantityBtn(Icons.remove, () => setState(() => quantity > 1 ? quantity-- : null)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: Text(quantity.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              _quantityBtn(Icons.add, () => setState(() => quantity++)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("Total Payable", style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text("₹$total", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2F6A3E))),
          ],
        )
      ],
    );
  }

  Widget _buildActionButtons(l10n) {
    return Row(
      children: [
        Expanded(
            child: OutlinedButton(
                onPressed: _addToCart,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text("ADD TO CART")
            )
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleBuyNow,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F6A3E), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: const Text("BUY NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _quantityBtn(IconData icon, VoidCallback onTap) {
    return IconButton(onPressed: onTap, icon: Icon(icon, color: const Color(0xFF2F6A3E)));
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2F6A3E)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF214B2D))),
        ],
      ),
    );
  }
}