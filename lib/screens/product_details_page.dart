import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'buy_now_page.dart';
import 'bulk_order_sheet.dart';

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

  Future<void> addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final variants = widget.product['variants'] ?? [];

    final price = variants.isNotEmpty ? variants[0]['mrpPrice'] ?? 0 : 0;

    await FirebaseFirestore.instance.collection('cart').add({
      'userId': user.uid,
      'productId': widget.productId,
      'name': widget.product['name'] ?? '',
      'price': price,
      'quantity': quantity,
      'image': widget.product['imageUrl'] ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Added to cart")));
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final image = product['imageUrl'] ?? '';
    final name = product['name'] ?? 'No Name';
    final description = product['description'] ?? '';
    final variants = product['variants'] ?? [];

    final price = variants.isNotEmpty ? variants[0]['mrpPrice'] ?? 0 : 0;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            image.isNotEmpty
                ? Image.network(
                    image,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image, size: 100),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(description),

                  const SizedBox(height: 20),

                  Text(
                    "₹$price",
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Variants
                  Column(
                    children: variants.map<Widget>((v) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(v['packingSize'] ?? ''),
                        subtitle: Text("₹${v['mrpPrice'] ?? 0}"),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 🔥 ROLE BASED UI
                  if (widget.role == 'Vendor') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                BulkOrderSheet(product: widget.product, role: widget.role),
                          );
                        },
                        child: const Text("Order in Bulk"),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: addToCart,
                        child: const Text("Add to Cart"),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BuyNowPage(
                                product: widget.product,
                                quantity: 1,
                                role: widget.role, // ✅ ADD THIS
                              ),
                            ),
                          );
                        },
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
