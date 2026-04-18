
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BuyNowPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final String role; // ✅ ADD ROLE

  const BuyNowPage({
    super.key,
    required this.product,
    required this.quantity,
    required this.role, // ✅ REQUIRED
  });

  @override
  State<BuyNowPage> createState() => _BuyNowPageState();
}

class _BuyNowPageState extends State<BuyNowPage> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final shopController = TextEditingController();
  final gstController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = widget.product['name'] ?? '';
  }

  Future<void> placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ✅ VALIDATION
    if (addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter address")),
      );
      return;
    }

    if (widget.role == 'Vendor' && shopController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter shop name")),
      );
      return;
    }

    final variants = widget.product['variants'] ?? [];
    final price =
        variants.isNotEmpty ? variants[0]['mrpPrice'] ?? 0 : 0;

    final total = price * widget.quantity;

    await FirebaseFirestore.instance.collection('orders').add({
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'totalAmount': total,

      'products': [
        {
          "productName": nameController.text,
          "imageUrl": widget.product['imageUrl'],
          "unitPrice": price,
          "quantity": widget.quantity,
          "totalPrice": total,
        }
      ],

      'address': addressController.text,

      // ✅ SAVE VENDOR DATA ONLY IF VENDOR
      if (widget.role == 'Vendor') ...{
        'shopName': shopController.text,
        'gst': gstController.text,
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order Placed Successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final variants = widget.product['variants'] ?? [];
    final price =
        variants.isNotEmpty ? variants[0]['mrpPrice'] ?? 0 : 0;

    final total = price * widget.quantity;

    return Scaffold(
      appBar: AppBar(title: const Text("Order")),
      body: SingleChildScrollView( // ✅ FIXED OVERFLOW
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Product"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Delivery Address"),
            ),

            const SizedBox(height: 20),

            // ✅ ONLY FOR VENDOR
            if (widget.role == 'Vendor') ...[
              TextField(
                controller: shopController,
                decoration: const InputDecoration(labelText: "Shop Name"),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: gstController,
                decoration: const InputDecoration(labelText: "GST Number"),
              ),
              const SizedBox(height: 10),
            ],

            Row(
              children: [
                const Text("Quantity: "),
                Text(
                  widget.quantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              "Total: ₹$total",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: placeOrder,
              child: const Text("Confirm Order"),
            ),
          ],
        ),
      ),
    );
  }
}

