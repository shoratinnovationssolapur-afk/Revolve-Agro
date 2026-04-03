import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import 'welcome_screen.dart';
import 'admin_gallery_screen.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String _selectedStatus = 'pending'; // pending, approved, rejected

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
                  subtitle: 'Manage and track customer orders',
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
              // Status filter tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatusFilterButton(
                        label: 'Pending',
                        status: 'pending',
                        isSelected: _selectedStatus == 'pending',
                        onPressed: () {
                          setState(() {
                            _selectedStatus = 'pending';
                          });
                        },
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _StatusFilterButton(
                        label: 'Approved',
                        status: 'approved',
                        isSelected: _selectedStatus == 'approved',
                        onPressed: () {
                          setState(() {
                            _selectedStatus = 'approved';
                          });
                        },
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _StatusFilterButton(
                        label: 'Rejected',
                        status: 'rejected',
                        isSelected: _selectedStatus == 'rejected',
                        onPressed: () {
                          setState(() {
                            _selectedStatus = 'rejected';
                          });
                        },
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('status', isEqualTo: _selectedStatus)
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
                        title: 'No $_selectedStatus orders',
                        subtitle:
                            'No orders with $_selectedStatus status found.',
                      );
                    }

                    return ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(18, 0, 18, 90),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final order =
                            snapshot.data!.docs[index];
                        final orderId = order.id;
                        final orderData =
                            order.data() as Map<String, dynamic>;

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: 16),
                          child: _OrderCard(
                            orderId: orderId,
                            userName:
                                orderData['userName'] ?? "User",
                            userEmail:
                                orderData['userEmail'] ?? "N/A",
                            products: orderData['products']
                                    as List<dynamic>? ??
                                [],
                            totalAmount:
                                orderData['totalAmount']
                                    .toString(),
                            status: orderData['status'] ?? 'pending',
                            deliveryAddress:
                                orderData['deliveryAddress']
                                    as Map<String, dynamic>?,
                            onApprove: _selectedStatus == 'pending' ? () {
                              _updateOrderStatus(context, orderId, 'approved');
                            } : null,
                            onReject: _selectedStatus == 'pending' ? () {
                              _updateOrderStatus(context, orderId, 'rejected');
                            } : null,
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

  void _updateOrderStatus(BuildContext context, String orderId, String newStatus) {
    FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({
          'status': newStatus,
          'updatedAt': DateTime.now(),
        })
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order $newStatus successfully'),
              backgroundColor: newStatus == 'approved' ? Colors.green : Colors.redAccent,
            ),
          );
        })
        .catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update order status'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final String userName;
  final String userEmail;
  final List<dynamic> products;
  final String totalAmount;
  final String status;
  final Map<String, dynamic>? deliveryAddress;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _OrderCard({
    required this.orderId,
    required this.userName,
    required this.userEmail,
    required this.products,
    required this.totalAmount,
    required this.status,
    this.deliveryAddress,
    this.onApprove,
    this.onReject,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
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
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Products: ${products.length}'),
            const SizedBox(height: 8),
            Text('Total Amount: \$${double.parse(totalAmount).toStringAsFixed(2)}'),
            if (deliveryAddress != null) ...[
              const SizedBox(height: 8),
              Text(
                'Delivery Address: ${deliveryAddress!['address'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'City: ${deliveryAddress!['city'] ?? 'N/A'}, ${deliveryAddress!['state'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    ElevatedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (onApprove != null)
                    ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusFilterButton extends StatelessWidget {
  final String label;
  final String status;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color color;

  const _StatusFilterButton({
    required this.label,
    required this.status,
    required this.isSelected,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onPressed(),
      backgroundColor: Colors.grey[200],
      selectedColor: color.withAlpha(100),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }
}