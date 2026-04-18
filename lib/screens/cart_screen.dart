
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> placeOrder(BuildContext context, List items) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double totalAmount = 0;

    for (var item in items) {
      totalAmount += item['price'] * item['quantity'];
    }

    await FirebaseFirestore.instance.collection('orders').add({
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'totalAmount': totalAmount,
      'products': items.map((item) {
        return {
          "productName": item['name'],
          "imageUrl": item['image'],
          "unitPrice": item['price'],
          "quantity": item['quantity'],
          "totalPrice": item['price'] * item['quantity'],
        };
      }).toList(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Order Placed")));

    // 🔥 OPTIONAL: clear cart
    final cartDocs = await FirebaseFirestore.instance
        .collection('cart')
        .where('userId', isEqualTo: user.uid)
        .get();

    for (var doc in cartDocs.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("My Cart")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cart')
            .where('userId', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          if (items.isEmpty) {
            return const Center(child: Text("Cart is empty"));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];

                    return ListTile(
                      leading: Image.network(item['image'], width: 50),
                      title: Text(item['name']),
                      subtitle: Text("Qty: ${item['quantity']}"),
                      trailing: Text("₹${item['price']}"),
                    );
                  },
                ),
              ),

              ElevatedButton(
                onPressed: () => placeOrder(context, items),
                child: const Text("Place Order"),
              )
            ],
          );
        },
      ),
    );
  }
}

