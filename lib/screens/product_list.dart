import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;


class Product {
  final String name;
  final String details;
  final String description;
  final String imageUrl;

  Product({
    required this.name,
    required this.details,
    required this.description,
    required this.imageUrl,
  });
}

class RevolveAgroProducts extends StatefulWidget {
  @override
  _RevolveAgroProductsState createState() => _RevolveAgroProductsState();
}

class _RevolveAgroProductsState extends State<RevolveAgroProducts> {
  // 1. Asynchronous function to fetch and parse website data
  Future<List<Product>> fetchProducts() async {
    const url = 'https://revolveagro.com';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var document = parser.parse(response.body);

      // Select all elements with the 'product' class from your HTML
      List<dom.Element> productElements = document.querySelectorAll('.product');

      return productElements.map((element) {
        return Product(
          name: element.querySelector('h3')?.text.trim() ?? 'Unknown Product',
          details: element.querySelector('.product-details')?.text.trim() ?? '',
          description: element.querySelector('.product-description')?.text.trim() ?? '',
          // Handles relative vs absolute image paths
          imageUrl: '$url/${element.querySelector('img')?.attributes['src'] ?? ''}',
        );
      }).toList();
    } else {
      throw Exception('Failed to load website');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Revolve Agro Products"),
        backgroundColor: Colors.green[800],
      ),
      body: FutureBuilder<List<Product>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            final products = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Image.network(
                        product.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 50),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900])),
                            SizedBox(height: 4),
                            Text(product.details, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                            SizedBox(height: 8),
                            Text(product.description, style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
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