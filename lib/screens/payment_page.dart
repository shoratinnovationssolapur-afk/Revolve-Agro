import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentPage extends StatefulWidget { // 1. Changed to StatefulWidget to handle UI updates after deletion
  final List<Map<String, dynamic>> cartItems;
  final int totalAmount;

  const PaymentPage({
    super.key,
    required this.cartItems,
    required this.totalAmount
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late List<Map<String, dynamic>> currentItems;
  late int currentTotal;

  @override
  void initState() {
    super.initState();
    currentItems = List.from(widget.cartItems);
    currentTotal = widget.totalAmount;
  }

  // 2. Function to remove item from Firestore and local UI
  Future<void> _removeItem(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String prodName = currentItems[index]['productName'];

    try {
      // Find the document in Firestore and delete it
      final querySnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: user.uid)
          .where('productName', isEqualTo: prodName)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        // Subtract the price of the removed item
        // Note: This assumes your map has 'totalPrice' or similar.
        // If not, we calculate using unitPrice * quantity
        int itemTotal = (currentItems[index]['quantity'] * 1500); // Using your fixed price 1500
        currentTotal -= itemTotal;
        currentItems.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$prodName removed from cart")),
      );
    } catch (e) {
      debugPrint("Error removing item: $e");
    }
  }

  Future<void> _handleFinalPayment(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (currentItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty!")),
      );
      return;
    }

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: user.uid)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc();

      batch.set(orderRef, {
        'userId': user.uid,
        'products': currentItems,
        'totalAmount': currentTotal,
        'status': 'Processing',
        'paymentStatus': 'Paid',
        'timestamp': FieldValue.serverTimestamp(),
      });

      for (var doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      if (mounted) _showSuccessDialog(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Order Placed!\nThe Revolve Agro team will contact you for delivery.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _contactSeller() async {
    final url = Uri.parse("tel:+917397820357");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA8C695),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text("Payment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Summary Card
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Order Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(),

                            // 3. Updated List with Remove Icon
                            ...List.generate(currentItems.length, (index) {
                              final item = currentItems[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Text(
                                      "+${item['quantity']}",
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(item['productName'], style: const TextStyle(fontSize: 15)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => _removeItem(index),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const Divider(height: 30),
                            _buildSummaryRow("Total Amount", "Rs.$currentTotal/="),
                            _buildSummaryRow("Delivery", "3 - 4 Day"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Payment Details
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text("Pay via Card", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                "Total: Rs.$currentTotal/=",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              _contactButton(),
              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: () => _handleFinalPayment(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2991E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                ),
                child: const Text("Pay Now", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // UI helper for contact button
  Widget _contactButton() {
    return InkWell(
      onTap: _contactSeller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Contact Seller", style: TextStyle(fontWeight: FontWeight.w500)),
            Icon(Icons.phone, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}