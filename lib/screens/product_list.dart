import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_page.dart';
import 'product_details_page.dart'; // Ensure you have created this file

class Product {
  final String name;
  final String details;
  final String description;
  final String imageUrl;
  final String price;

  Product({
    required this.name,
    required this.details,
    required this.description,
    required this.imageUrl,
    this.price = "Request Quote",
  });
}

class RevolveAgroProducts extends StatefulWidget {
  @override
  _RevolveAgroProductsState createState() => _RevolveAgroProductsState();
}

class _RevolveAgroProductsState extends State<RevolveAgroProducts> {

  Future<List<Product>> fetchProducts() async {
    const url = 'https://revolveagro.com';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        List<dom.Element> productElements = document.querySelectorAll('.product');

        return productElements.map((element) {
          return Product(
            name: element.querySelector('h3')?.text.trim() ?? 'Unknown Product',
            details: element.querySelector('.product-details')?.text.trim() ?? '',
            description: element.querySelector('.product-description')?.text.trim() ?? '',
            imageUrl: '$url/${element.querySelector('img')?.attributes['src'] ?? ''}',
          );
        }).toList();
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Check your internet connection');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0), // Light greenish tint background
      appBar: AppBar(
        title: const Text("Revolve Agro Products", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // --- ADDED FLOATING ACTION BUTTON ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCart(context),
        backgroundColor: const Color(0xFFF2991E), // Match your "Pay Now" orange
        icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
        label: const Text("View Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 8,
      ),

      body: FutureBuilder<List<Product>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("${snapshot.error}", textAlign: TextAlign.center),
              ),
            );
          } else {
            final products = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsPage(product: product),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: product.name,
                          child: Image.network(
                            product.imageUrl,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(product.name),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

// --- LOGIC TO OPEN CART DIRECTLY ---
  Future<void> _openCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to view your cart")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
      const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: user.uid)
          .get();

      Navigator.pop(context);

      if (cartSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your cart is empty")),
        );
        return;
      }

      List<Map<String, dynamic>> items = [];
      int total = 0;

      for (var doc in cartSnapshot.docs) {
        items.add({
          'productName': doc['productName'],
          'quantity': doc['quantity'],
        });
        total += (doc['totalPrice'] as num).toInt();
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
        SnackBar(content: Text("Error fetching cart: $e")),
      );
    }
  }
}