import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'product_list.dart';
import 'payment_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;
  final int unitPrice = 1500;

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to add items to cart")),
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
            content: Text("${widget.product.name} added to cart!"),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () async {
                final cartSnapshot = await FirebaseFirestore.instance
                    .collection('cart')
                    .where('userId', isEqualTo: user.uid)
                    .get();

                List<Map<String, dynamic>> items = [];
                int total = 0;

                for (var doc in cartSnapshot.docs) {
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
        SnackBar(content: Text("Failed to add to cart: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showZoomedImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  widget.product.imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalAmount = unitPrice * quantity;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image with Zoom
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: GestureDetector(
              onTap: () => _showZoomedImage(context),
              child: Hero(
                tag: widget.product.name,
                child: Image.network(
                  widget.product.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Detail Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                color: Color(0xFFE0E0E0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.details,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.product.description,
                        style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quantity and Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _quantityBtn(Icons.add_circle_outline, () => setState(() => quantity++)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(quantity.toString().padLeft(2, '0'),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          _quantityBtn(Icons.remove_circle_outline, () {
                            if (quantity > 1) setState(() => quantity--);
                          }),
                        ],
                      ),
                      Text(
                        "RS.$totalAmount/=",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          "Buy Now",
                          const Color(0xFF4CAF50),
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentPage(
                                  cartItems: [{
                                    'productName': widget.product.name,
                                    'quantity': quantity,
                                  }],
                                  totalAmount: totalAmount,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _actionBtn(
                            "Add to Cart",
                            const Color(0xFFB5A144),
                            _addToCart
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityBtn(IconData icon, VoidCallback iconTap) {
    return IconButton(
      onPressed: iconTap,
      icon: Icon(icon, size: 30, color: Colors.black),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}