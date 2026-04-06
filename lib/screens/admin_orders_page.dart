import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
// ✅ added

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF3DE),
              Color(0xFFF7F3E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // HEADER
// Replace the current Header Padding block with this simplified version:
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF183020), Color(0xFF30523B)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => Navigator.pop(context), // Simple back to Dashboard
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            l10n.text('incoming_orders'), // Or "Orders"
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.text('incoming_orders_subtitle'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ORDERS LIST
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inbox_outlined,
                                  size: 54, color: Color(0xFF2F6A3E)),
                              const SizedBox(height: 12),
                              Text(
                                l10n.text('no_orders_found'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final order = snapshot.data!.docs[index];
                        final orderData =
                        order.data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _OrderCard(
                            userName: orderData['userName'] ?? "User",
                            products:
                            orderData['products'] as List<dynamic>? ?? [],
                            totalAmount: orderData['totalAmount'].toString(),
                            deliveryAddress:
                            orderData['deliveryAddress']
                            as Map<String, dynamic>?,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ RESTORED (IMPORTANT FIX)
class _OrderCard extends StatelessWidget {
  final String userName;
  final List<dynamic> products;
  final String totalAmount;
  final Map<String, dynamic>? deliveryAddress;

  const _OrderCard({
    required this.userName,
    required this.products,
    required this.totalAmount,
    required this.deliveryAddress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final addressParts = [
      deliveryAddress?['fullAddress']?.toString() ?? '',
      deliveryAddress?['landmark']?.toString() ?? '',
      deliveryAddress?['city']?.toString() ?? '',
      deliveryAddress?['pincode']?.toString() ?? '',
    ].where((part) => part.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              const Icon(Icons.person_outline),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...products.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "${item['productName']} (Qty: ${item['quantity']})",
            ),
          )),

          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.text('total_received')),
              Text(
                "Rs.$totalAmount/=",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F6A3E),
                ),
              ),
            ],
          ),

          if (addressParts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(addressParts.join(', ')),
          ],
        ],
      ),
    );
  }
}