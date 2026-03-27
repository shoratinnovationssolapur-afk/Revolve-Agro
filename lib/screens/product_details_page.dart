import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'product_list.dart'; // Import your Product model

class ProductDetailsPage extends StatelessWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  // WhatsApp Buy Logic (Matches your website's WhatsApp 73978 20357)
  void _buyViaWhatsApp() async {
    final message = "Hello Revolve Agro, I want to buy ${product.name}.\nDetails: ${product.details}";
    final url = "https://wa.me/917397820357?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Hero animation
            Hero(
              tag: product.name,
              child: Image.network(
                product.imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 100)
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name & Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.verified, color: Colors.green),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Technical Details
                  Text(
                    product.details,
                    style: TextStyle(fontSize: 18, color: Colors.green[700], fontWeight: FontWeight.w600),
                  ),
                  const Divider(height: 30),

                  // Price Section
                  const Text("Estimated Price:", style: TextStyle(color: Colors.grey)),
                  Text(
                    product.price,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text("About this Product:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ],
        ),
      ),

      // Fixed Buy Button at bottom
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
        ),
        child: ElevatedButton(
          onPressed: _buyViaWhatsApp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[800],
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart),
              SizedBox(width: 10),
              Text("BUY NOW / ENQUIRE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}