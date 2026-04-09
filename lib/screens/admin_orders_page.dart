import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3DE), Color(0xFFF7F3E8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔥 INTEGRATED HEADER SECTION
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
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              l10n.text('incoming_orders'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminGalleryScreen()),
                              );
                            },
                            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
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

              // 🔥 STATUS FILTER TABS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatusFilterButton(
                        label: 'Pending',
                        isSelected: _selectedStatus == 'pending',
                        onPressed: () => setState(() => _selectedStatus = 'pending'),
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _StatusFilterButton(
                        label: 'Approved',
                        isSelected: _selectedStatus == 'approved',
                        onPressed: () => setState(() => _selectedStatus = 'approved'),
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _StatusFilterButton(
                        label: 'Rejected',
                        isSelected: _selectedStatus == 'rejected',
                        onPressed: () => setState(() => _selectedStatus = 'rejected'),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🔥 ORDERS LIST
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('status', isEqualTo: _selectedStatus)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text("No $_selectedStatus orders found"),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final order = snapshot.data!.docs[index];
                        final orderId = order.id;
                        final orderData = order.data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _OrderCard(
                            orderId: orderId,
                            userName: orderData['userName'] ?? "User",
                            userEmail: orderData['userEmail'] ?? "N/A",
                            products: orderData['products'] as List<dynamic>? ?? [],
                            totalAmount: orderData['totalAmount'].toString(),
                            status: orderData['status'] ?? 'pending',
                            deliveryAddress: orderData['deliveryAddress'] as Map<String, dynamic>?,
                            onApprove: _selectedStatus == 'pending' ? () => _updateOrderStatus(context, orderId, 'approved') : null,
                            onReject: _selectedStatus == 'pending' ? () => _updateOrderStatus(context, orderId, 'rejected') : null,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...products.map((item) => Text("• ${item['productName']} (Qty: ${item['quantity']})")),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount:"),
              Text("Rs. $totalAmount", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2F6A3E))),
            ],
          ),
          if (onApprove != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: onReject, child: const Text("Reject", style: TextStyle(color: Colors.red))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(onPressed: onApprove, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Approve", style: TextStyle(color: Colors.white))),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}

class _StatusFilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color color;

  const _StatusFilterButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onPressed(),
      selectedColor: color,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }
}
