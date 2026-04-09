import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/app_shell.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String _selectedFilter = 'all'; // all, pending, approved, rejected

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: AppShell(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Track your order status',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterButton(
                        label: 'All Orders',
                        isSelected: _selectedFilter == 'all',
                        onPressed: () {
                          setState(() {
                            _selectedFilter = 'all';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterButton(
                        label: 'Pending',
                        isSelected: _selectedFilter == 'pending',
                        onPressed: () {
                          setState(() {
                            _selectedFilter = 'pending';
                          });
                        },
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _FilterButton(
                        label: 'Approved',
                        isSelected: _selectedFilter == 'approved',
                        onPressed: () {
                          setState(() {
                            _selectedFilter = 'approved';
                          });
                        },
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _FilterButton(
                        label: 'Rejected',
                        isSelected: _selectedFilter == 'rejected',
                        onPressed: () {
                          setState(() {
                            _selectedFilter = 'rejected';
                          });
                        },
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Orders list
              Expanded(
                child: user == null
                    ? const Center(
                        child: Text('Please log in to see your orders'),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: _buildOrdersStream(user.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Failed to load orders',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            );
                          }

                          final docs = _filterOrders(snapshot.data?.docs ?? const []);

                          if (docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No orders found',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You don\'t have any ${_selectedFilter == 'all' ? '' : _selectedFilter} orders yet.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final order = docs[index];
                              final orderData =
                                  order.data() as Map<String, dynamic>;
                              final status = _normalizeStatus(orderData['status']);
                              final timestamp =
                                  (orderData['timestamp'] as Timestamp?)
                                      ?.toDate();

                              return OrderStatusCard(
                                orderId: order.id,
                                status: status,
                                totalAmount: orderData['totalAmount']
                                    .toString(),
                                productCount:
                                    (orderData['products'] as List?)?.length ??
                                        0,
                                orderDate: timestamp,
                                rejectionReason: orderData['rejectionReason'],
                                trackingStatus: orderData['trackingStatus'] ?? 'none',
                                statusHistory: (orderData['statusHistory'] as List?) ?? [],
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

  Stream<QuerySnapshot> _buildOrdersStream(String userId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterOrders(List<QueryDocumentSnapshot> docs) {
    if (_selectedFilter == 'all') {
      return docs;
    }

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _normalizeStatus(data['status']) == _selectedFilter;
    }).toList();
  }

  String _normalizeStatus(dynamic rawStatus) {
    final value = rawStatus?.toString().trim().toLowerCase();
    if (value == 'approved' || value == 'rejected' || value == 'pending') {
      return value!;
    }
    return 'pending';
  }
}

class OrderStatusCard extends StatefulWidget {
  final String orderId;
  final String status;
  final String totalAmount;
  final int productCount;
  final DateTime? orderDate;
  final String? rejectionReason;
  final String trackingStatus;
  final List<dynamic> statusHistory;

  const OrderStatusCard({
    super.key,
    required this.orderId,
    required this.status,
    required this.totalAmount,
    required this.productCount,
    this.orderDate,
    this.rejectionReason,
    this.trackingStatus = 'none',
    this.statusHistory = const [],
  });

  @override
  State<OrderStatusCard> createState() => _OrderStatusCardState();
}

class _OrderStatusCardState extends State<OrderStatusCard> {
  bool _expandedTimeline = false;

  Color _getStatusColor() {
    switch (widget.status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusMessage() {
    switch (widget.status) {
      case 'approved':
        return 'Your order has been approved!';
      case 'rejected':
        return 'Your order was rejected';
      default:
        return 'Your order is pending approval';
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }

  String _getTrackingStatusLabel() {
    switch (widget.trackingStatus) {
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Not Yet Started';
    }
  }

  IconData _getTrackingIcon() {
    switch (widget.trackingStatus) {
      case 'processing':
        return Icons.hourglass_bottom;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      default:
        return Icons.pending_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${widget.orderId}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.orderDate != null)
                        Text(
                          'Placed on ${_formatDate(widget.orderDate!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(),
                        size: 18,
                        color: _getStatusColor(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getStatusMessage(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Rejection Reason (if rejected)
            if (widget.rejectionReason != null && 
                widget.rejectionReason!.isNotEmpty) ...[
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
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.rejectionReason!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Tracking Status (if approved)
            if (widget.status == 'approved' && widget.trackingStatus != 'none') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTrackingIcon(),
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery Status:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTrackingStatusLabel(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Order details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.productCount} item${widget.productCount != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Total: \$${double.parse(widget.totalAmount).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Status Timeline
            if (widget.statusHistory.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  setState(() => _expandedTimeline = !_expandedTimeline);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Order Timeline',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Icon(
                        _expandedTimeline
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expandedTimeline) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...List.generate(widget.statusHistory.length, (index) {
                        final item = widget.statusHistory[index] as Map<String, dynamic>?;
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

                        final statusColor = itemStatus == 'approved'
                            ? Colors.green
                            : itemStatus == 'rejected'
                                ? Colors.red
                                : Colors.orange;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemStatus.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: statusColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeStr,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (itemReason != null &&
                                        itemReason.toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Reason: ${itemReason.toString()}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final orderDay = DateTime(date.year, date.month, date.day);

    if (orderDay == today) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (orderDay == yesterday) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color? color;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onPressed(),
      backgroundColor: Colors.grey[200],
      selectedColor: (color ?? Colors.blue).withAlpha(100),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? (color ?? Colors.blue) : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }
}
