import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import '../widgets/language_selector.dart';
import 'profile_page.dart';
import 'welcome_screen.dart';
import 'admin_gallery_screen.dart'; // ✅ added

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: AppShell(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: AppPageHeader(
                  title: l10n.text('incoming_orders'),
                  subtitle: l10n.text('incoming_orders_subtitle'),
                  badgeIcon: Icons.inventory_2_outlined,
                  leading: IconButton.filledTonal(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WelcomeScreen(preferredRole: 'Admin'),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  actions: [
                    IconButton.filledTonal(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminGalleryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                    ),
                    const SizedBox(width: 8),
                    const LanguageSelector(),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(role: 'Admin'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.admin_panel_settings_rounded),
                    ),
                  ],
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
                      return AppEmptyState(
                        icon: Icons.inbox_outlined,
                        title: l10n.text('no_orders_found'),
                        subtitle: 'New customer orders will appear here as soon as they are placed.',
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
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F1D9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_outline, color: Color(0xFF2F6A3E)),
              ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EEDC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '${products.length} item(s) in this order',
              style: const TextStyle(
                color: Color(0xFF8A5D1A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),

          ...products.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 18, color: Color(0xFF2F6A3E)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${item['productName']} (Qty: ${item['quantity']})",
                    ),
                  ),
                ],
              ),
            ),
          ),

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
