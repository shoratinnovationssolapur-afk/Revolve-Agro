import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import 'welcome_screen.dart';
import 'admin_gallery_screen.dart';
import '../services/email_service.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String _selectedStatus = 'pending'; // pending, approved, rejected
  final Set<String> _selectedOrderIds = {}; // For bulk actions

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
              // Bulk Actions Toolbar
              if (_selectedOrderIds.isNotEmpty)
                Container(
                  color: Colors.blue[50],
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selectedOrderIds.length} order${_selectedOrderIds.length > 1 ? 's' : ''} selected',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (_selectedStatus == 'pending') ...[
                        OutlinedButton.icon(
                          onPressed: () => _bulkApproveOrders(),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve All'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _bulkRejectOrders(),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject All'),
                        ),
                      ],
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _selectedOrderIds.clear());
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              // Status filter tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                            _selectedOrderIds.clear();
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
                            _selectedOrderIds.clear();
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
                            _selectedOrderIds.clear();
                          });
                        },
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),

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
                            rejectionReason: orderData['rejectionReason'],
                            trackingStatus: orderData['trackingStatus'] ?? 'none',
                            statusHistory: (orderData['statusHistory'] as List?) ?? [],
                            timestamp: orderData['timestamp'],
                            isSelected: _selectedOrderIds.contains(orderId),
                            onSelectionChanged: _selectedStatus == 'pending'
                                ? (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedOrderIds.add(orderId);
                                      } else {
                                        _selectedOrderIds.remove(orderId);
                                      }
                                    });
                                  }
                                : null,
                            onApprove: _selectedStatus == 'pending' ? () {
                              _showApproveDialog(context, orderId, orderData);
                            } : null,
                            onReject: _selectedStatus == 'pending' ? () {
                              _showRejectDialog(context, orderId, orderData);
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

  Future<void> _showApproveDialog(
    BuildContext context,
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Order'),
        content: const Text('Are you sure you want to approve this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateOrderStatus(context, orderId, 'approved', orderData);
    }
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    final reasonController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a rejection reason')),
                );
                return;
              }
              Navigator.pop(
                context,
                {'reason': reasonController.text.trim()},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _updateOrderStatus(
        context,
        orderId,
        'rejected',
        orderData,
        rejectionReason: result['reason'],
      );
    }
  }

  Future<void> _updateOrderStatus(
    BuildContext context,
    String orderId,
    String newStatus,
    Map<String, dynamic> orderData, {
    String? rejectionReason,
  }) async {
    try {
      final timestamp = DateTime.now();
      final statusHistory = (orderData['statusHistory'] as List?) ?? [];
      
      statusHistory.add({
        'status': newStatus,
        'timestamp': timestamp,
        'reason': rejectionReason,
      });

      final updateData = {
        'status': newStatus,
        'updatedAt': timestamp,
        'statusHistory': statusHistory,
      };

      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }

      // Update tracking status for approved orders
      if (newStatus == 'approved') {
        updateData['trackingStatus'] = 'processing';
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update(updateData);

      // Send email notification
      final userEmail = orderData['userEmail'] ?? '';
      final userName = orderData['userName'] ?? 'User';
      final totalAmount = (orderData['totalAmount'] as num?)?.toDouble() ?? 0.0;

      if (newStatus == 'approved') {
        await EmailService.sendOrderApprovalEmail(
          userEmail: userEmail,
          userName: userName,
          orderId: orderId,
          totalAmount: totalAmount,
        );
      } else if (newStatus == 'rejected' && rejectionReason != null) {
        await EmailService.sendOrderRejectionEmail(
          userEmail: userEmail,
          userName: userName,
          orderId: orderId,
          totalAmount: totalAmount,
          rejectionReason: rejectionReason,
        );
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order $newStatus successfully. Email sent to user.'),
          backgroundColor: newStatus == 'approved' ? Colors.green : Colors.redAccent,
        ),
      );

      setState(() => _selectedOrderIds.remove(orderId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bulkApproveOrders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Multiple Orders'),
        content: Text(
          'Are you sure you want to approve ${_selectedOrderIds.length} order${_selectedOrderIds.length > 1 ? 's' : ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final timestamp = DateTime.now();

      for (final orderId in _selectedOrderIds) {
        final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
        final orderDoc = await orderRef.get();
        final orderData = orderDoc.data() as Map<String, dynamic>? ?? {};

        final statusHistory = (orderData['statusHistory'] as List?) ?? [];
        statusHistory.add({
          'status': 'approved',
          'timestamp': timestamp,
        });

        batch.update(orderRef, {
          'status': 'approved',
          'trackingStatus': 'processing',
          'updatedAt': timestamp,
          'statusHistory': statusHistory,
        });

        // Send emails
        final userEmail = orderData['userEmail'] ?? '';
        final userName = orderData['userName'] ?? 'User';
        final totalAmount = (orderData['totalAmount'] as num?)?.toDouble() ?? 0.0;

        await EmailService.sendOrderApprovalEmail(
          userEmail: userEmail,
          userName: userName,
          orderId: orderId,
          totalAmount: totalAmount,
        );
      }

      await batch.commit();

      if (!context.mounted) return;

      final count = _selectedOrderIds.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count order${count > 1 ? 's' : ''} approved. Emails sent.'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _selectedOrderIds.clear());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bulkRejectOrders() async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Multiple Orders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Provide a reason for rejecting ${_selectedOrderIds.length} order${_selectedOrderIds.length > 1 ? 's' : ''}:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a rejection reason')),
                );
                return;
              }
              Navigator.pop(context, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject All'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final timestamp = DateTime.now();

      for (final orderId in _selectedOrderIds) {
        final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
        final orderDoc = await orderRef.get();
        final orderData = orderDoc.data() as Map<String, dynamic>? ?? {};

        final statusHistory = (orderData['statusHistory'] as List?) ?? [];
        statusHistory.add({
          'status': 'rejected',
          'timestamp': timestamp,
          'reason': reason,
        });

        batch.update(orderRef, {
          'status': 'rejected',
          'rejectionReason': reason,
          'updatedAt': timestamp,
          'statusHistory': statusHistory,
        });

        // Send emails
        final userEmail = orderData['userEmail'] ?? '';
        final userName = orderData['userName'] ?? 'User';
        final totalAmount = (orderData['totalAmount'] as num?)?.toDouble() ?? 0.0;

        await EmailService.sendOrderRejectionEmail(
          userEmail: userEmail,
          userName: userName,
          orderId: orderId,
          totalAmount: totalAmount,
          rejectionReason: reason,
        );
      }

      await batch.commit();

      if (!context.mounted) return;

      final count = _selectedOrderIds.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count order${count > 1 ? 's' : ''} rejected. Emails sent.'),
          backgroundColor: Colors.redAccent,
        ),
      );

      setState(() => _selectedOrderIds.clear());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
  final String? rejectionReason;
  final String trackingStatus;
  final List<dynamic> statusHistory;
  final dynamic timestamp;
  final bool isSelected;
  final Function(bool)? onSelectionChanged;
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
    this.rejectionReason,
    this.trackingStatus = 'none',
    this.statusHistory = const [],
    this.timestamp,
    this.isSelected = false,
    this.onSelectionChanged,
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

  String _getTrackingStatusLabel() {
    switch (trackingStatus) {
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      default:
        return 'No Tracking';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 2,
      color: isSelected ? Colors.blue[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with selection checkbox
            Row(
              children: [
                if (onSelectionChanged != null)
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => onSelectionChanged?.call(value ?? false),
                  ),
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

            // Tracking Status Badge (for approved orders)
            if (status == 'approved' && trackingStatus != 'none') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_shipping, size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      _getTrackingStatusLabel(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Order Details
            Text('Products: ${products.length}'),
            const SizedBox(height: 8),
            Text('Total Amount: \$${double.parse(totalAmount).toStringAsFixed(2)}'),
            if (deliveryAddress != null) ...[
              const SizedBox(height: 8),
              Text(
                'Delivery Address: ${deliveryAddress!['fullAddress'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'City: ${deliveryAddress!['city'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 12),
              ),
            ],

            // Rejection Reason (if rejected)
            if (rejectionReason != null && rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rejection Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rejectionReason!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],

            // Status Timeline
            if (statusHistory.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Timeline:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(statusHistory.length, (index) {
                      final item = statusHistory[index] as Map<String, dynamic>?;
                      if (item == null) return const SizedBox.shrink();

                      final itemStatus = item['status'] ?? 'unknown';
                      final itemTimestamp = item['timestamp'];
                      final itemReason = item['reason'];

                      String timeStr = 'N/A';
                      if (itemTimestamp is Timestamp) {
                        final dateTime = itemTimestamp.toDate();
                        timeStr =
                            '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: itemStatus == 'approved'
                                    ? Colors.green
                                    : itemStatus == 'rejected'
                                        ? Colors.red
                                        : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemStatus.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (itemReason != null && itemReason.toString().isNotEmpty)
                                    Text(
                                      'Reason: ${itemReason.toString()}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            // Action Buttons
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