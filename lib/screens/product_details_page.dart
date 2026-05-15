import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'bulk_order_sheet.dart';
import 'payment_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final String productId;
  final String role;

  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.productId,
    required this.role,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;
  Map<String, dynamic>? _selectedVariant;

  @override
  void initState() {
    super.initState();

    final variants = widget.product['variants'] ?? [];

    if (variants.isNotEmpty) {
      _selectedVariant = variants.first;
    } else {
      _selectedVariant = {
        'packingSize': 'Standard',
        'drpPrice': widget.product['price'] ?? 0,
        'mrpPrice': widget.product['price'] ?? 0,
      };
    }
  }

  int get _currentDRP => (_selectedVariant?['drpPrice'] ?? 0).toInt();
  int get _currentMRP => (_selectedVariant?['mrpPrice'] ?? 0).toInt();
  String get _currentSize => _selectedVariant?['packingSize'] ?? '';

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('cart').add({
      'userId': user.uid,
      'productId': widget.productId,
      'productName': "${widget.product['name']} ($_currentSize)",
      'quantity': quantity,
      'unitPrice': _currentDRP,
      'totalPrice': _currentDRP * quantity,
      'imageUrl': widget.product['imageUrl'],
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Added to cart")));
  }

  void _handleBuyNow() {
    final totalAmount = _currentDRP * quantity;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          cartItems: [
            {
              'productName': "${widget.product['name']} ($_currentSize)",
              'quantity': quantity,
              'productId': widget.productId,
              'unitPrice': _currentDRP,
              'totalPrice': totalAmount,
              'imageUrl': widget.product['imageUrl'],
            }
          ],
          totalAmount: totalAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final variants = product['variants'] ?? [];

    final discount = _currentMRP > 0
        ? ((_currentMRP - _currentDRP) / _currentMRP) * 100
        : 0;

    return Scaffold(
      appBar: AppBar(title: Text(product['name'] ?? 'Product')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              product['imageUrl'] ?? '',
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),
                  Text(product['description'] ?? ''),

                  const SizedBox(height: 20),

                  /// 🔥 Variant Selector
                  SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: variants.length,
                      itemBuilder: (context, index) {
                        final v = variants[index];
                        final isSelected = _selectedVariant == v;

                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(v['packingSize'] ?? ''),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _selectedVariant = v);
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔥 Price Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("MRP"),
                            Text("₹$_currentMRP",
                                style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.red)),
                          ],
                        ),
                        if (discount > 0)
                          Text("${discount.toStringAsFixed(0)}% OFF",
                              style: const TextStyle(color: Colors.green)),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Price",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("₹$_currentDRP",
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔥 Quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                              onPressed: () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                }
                              },
                              icon: const Icon(Icons.remove)),
                          Text(quantity.toString()),
                          IconButton(
                              onPressed: () {
                                setState(() => quantity++);
                              },
                              icon: const Icon(Icons.add)),
                        ],
                      ),
                      Text("Total: ₹${_currentDRP * quantity}",
                          style: const TextStyle(fontSize: 18)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// 🔥 ROLE BASED UI
                  if (widget.role == 'Vendor') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => BulkOrderSheet(
                              product: widget.product,
                              role: widget.role,
                            ),
                          );
                        },
                        child: const Text("Order in Bulk"),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addToCart,
                        child: const Text("Add to Cart"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleBuyNow,
                        child: const Text("Buy Now"),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}