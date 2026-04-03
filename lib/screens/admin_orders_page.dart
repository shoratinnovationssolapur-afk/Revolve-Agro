import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import 'welcome_screen.dart';
import 'admin_gallery_screen.dart';

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
                          builder: (context) =>
                              const WelcomeScreen(preferredRole: 'Admin'),
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
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.inbox_outlined,
                        title: l10n.text('no_orders_found'),
                        subtitle:
                            'New customer orders will appear here as soon as they are placed.',
                      );
                    }

                    return ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(18, 0, 18, 90),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final order =
                            snapshot.data!.docs[index];
                        final orderData =
                            order.data() as Map<String, dynamic>;

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: 16),
                          child: _OrderCard(
                            userName:
                                orderData['userName'] ?? "User",
                            products: orderData['products']
                                    as List<dynamic>? ??
                                [],
                            totalAmount:
                                orderData['totalAmount']
                                    .toString(),
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

class _OrderCard extends StatelessWidget {
  final String userName;
  final List<dynamic> products;
  final String totalAmount;
  final Map<String, dynamic>? deliveryAddress;

  const _OrderCard({
    required this.userName,
    required this.products,
    required this.totalAmount,
    this.deliveryAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Products: ${products.length}'),
            const SizedBox(height: 8),
            Text('Total Amount: \$$totalAmount'),
            if (deliveryAddress != null) ...[
              const SizedBox(height: 8),
              Text(
                'Delivery Address: ${deliveryAddress!['address'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 12),
              ),
            ]
          ],
        ),
      ),
    );
  }
}