import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/language_selector.dart';
import 'auth_screen.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AuthScreen(role: "Admin")),
              (route) => false,
            );
          }
        },
        backgroundColor: const Color(0xFF183020),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.power_settings_new_rounded),
        label: Text(l10n.text('logout')),
      ),
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
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                          const LanguageSelector(),
                          const SizedBox(width: 12),
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.text('incoming_orders'),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                              const Icon(Icons.inbox_outlined, size: 54, color: Color(0xFF2F6A3E)),
                              const SizedBox(height: 12),
                              Text(
                                l10n.text('no_orders_found'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                        final orderData = order.data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _OrderCard(
                            userName: orderData['userName'] ?? "User",
                            products: orderData['products'] as List<dynamic>? ?? [],
                            totalAmount: orderData['totalAmount'].toString(),
                            deliveryAddress: orderData['deliveryAddress'] as Map<String, dynamic>?,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2DF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_outline_rounded, color: Color(0xFF2F6A3E)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183020),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E8CF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  l10n.text('processing'),
                  style: TextStyle(
                    color: Color(0xFF8C5B1C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...products.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        item['imageUrl'] ?? "https://via.placeholder.com/150",
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 56,
                          width: 56,
                          color: const Color(0xFFE8E4DB),
                          child: const Icon(Icons.image_outlined, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['productName'],
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Quantity: ${item['quantity']}",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.text('total_received'),
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              Text(
                "Rs.$totalAmount/=",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Color(0xFF2F6A3E),
                ),
              ),
            ],
          ),
          if (addressParts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F2E7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFFD9952E)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      addressParts.join(', '),
                      style: const TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
