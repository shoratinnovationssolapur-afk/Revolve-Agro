import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
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
      body: FutureBuilder<List<Product>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
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

                // Wrap in InkWell to make it clickable
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsPage(product: product),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias, // Ensures image follows card curves
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Animation for the image
                        Hero(
                          tag: product.name,
                          child: Image.network(
                            product.imageUrl,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 220,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  product.name,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900])
                              ),
                              const SizedBox(height: 5),
                              Text(
                                  product.details,
                                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600, fontSize: 14)
                              ),
                              const SizedBox(height: 10),
                              Text(
                                product.description,
                                maxLines: 2, // Keeps the list tidy
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                children: [
                                  Text("View Details", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  Icon(Icons.chevron_right, color: Colors.blue, size: 18),
                                ],
                              )
                            ],
                          ),
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
}