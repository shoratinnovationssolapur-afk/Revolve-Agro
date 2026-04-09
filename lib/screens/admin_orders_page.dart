import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

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
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
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
                        child: Text("No $_selectedStatus orders found"),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final order = docs[index];
                        final orderId = order.id;
                        final orderData = order.data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _OrderCard(
                            orderId: orderId,
                            userId: orderData['userId']?.toString() ?? '',
                            fallbackUserName: orderData['userName'] ?? "User",
                            fallbackUserEmail: orderData['userEmail'] ?? "N/A",
                            products: orderData['products'] as List<dynamic>? ?? [],
                            totalAmount: orderData['totalAmount'].toString(),
                            status: _normalizeStatus(orderData['status']),
                            deliveryAddress: orderData['deliveryAddress'] as Map<String, dynamic>?,
                            orderedAt: (orderData['timestamp'] as Timestamp?)?.toDate(),
                            updatedAt: (orderData['updatedAt'] as Timestamp?)?.toDate(),
                            currentLocationLabel: l10n.text('current_location'),
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

  List<QueryDocumentSnapshot> _filterOrders(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _normalizeStatus(data['status']) == _selectedStatus;
    }).toList();
  }

  String _normalizeStatus(dynamic rawStatus) {
    final value = rawStatus?.toString().trim().toLowerCase();
    if (value == 'approved' || value == 'rejected' || value == 'pending') {
      return value!;
    }
    return 'pending';
  }

  void _updateOrderStatus(BuildContext context, String orderId, String newStatus) {
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
    final actionTime = Timestamp.now();

    orderRef.get().then((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      final rawHistory = data['statusHistory'] as List? ?? [];
      final statusHistory = List<Map<String, dynamic>>.from(
        rawHistory.map((item) => Map<String, dynamic>.from(item as Map)),
      );

      statusHistory.add({
        'status': newStatus,
        'timestamp': actionTime,
      });

      return orderRef.update({
        'status': newStatus,
        'updatedAt': actionTime,
        'statusHistory': statusHistory,
      });
    }).then((_) {
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
  final String userId;
  final String fallbackUserName;
  final String fallbackUserEmail;
  final List<dynamic> products;
  final String totalAmount;
  final String status;
  final Map<String, dynamic>? deliveryAddress;
  final DateTime? orderedAt;
  final DateTime? updatedAt;
  final String currentLocationLabel;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _OrderCard({
    required this.orderId,
    required this.userId,
    required this.fallbackUserName,
    required this.fallbackUserEmail,
    required this.products,
    required this.totalAmount,
    required this.status,
    this.deliveryAddress,
    this.orderedAt,
    this.updatedAt,
    required this.currentLocationLabel,
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
              Expanded(
                child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: userId.isEmpty
                      ? null
                      : FirebaseFirestore.instance.collection('users').doc(userId).get(),
                  builder: (context, snapshot) {
                    final userData = snapshot.data?.data();
                    final customerName =
                        userData?['name']?.toString().trim().isNotEmpty == true
                            ? userData!['name'].toString().trim()
                            : fallbackUserName;
                    final customerEmail =
                        userData?['email']?.toString().trim().isNotEmpty == true
                            ? userData!['email'].toString().trim()
                            : fallbackUserEmail;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customerEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (orderedAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Ordered on ${_formatDateTime(orderedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (status != 'pending' && updatedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${status == 'approved' ? 'Approved' : 'Rejected'} on ${_formatDateTime(updatedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: status == 'approved' ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
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
// 🔥 NEW: Enhanced Product List with Images & Prices
          ...products.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item['imageUrl'] ?? '',
                      width: 45, height: 45, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.shopping_basket_outlined),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['productName'] ?? "Product", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Qty: ${item['quantity']} | Rate: ₹${item['unitPrice']}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Text("₹${item['totalPrice']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),

          const Divider(height: 24),

          // 🔥 NEW: Delivery Address Section
          if (deliveryAddress != null) ...[
            const Text("Delivery Address:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            FutureBuilder<List<String>>(
              future: _resolveAddressLines(deliveryAddress!),
              builder: (context, snapshot) {
                final lines = snapshot.data ??
                    <String>[
                      _primaryAddressLine(deliveryAddress!),
                      _secondaryAddressLine(deliveryAddress!),
                    ];
                final primary = lines.isNotEmpty ? lines[0] : '';
                final secondary = lines.length > 1 ? lines[1] : '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(primary, style: const TextStyle(fontSize: 14)),
                    if (secondary.trim().isNotEmpty)
                      Text(secondary, style: const TextStyle(fontSize: 14)),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Final Payable Amount:", style: TextStyle(fontWeight: FontWeight.w600)),
              Text("₹$totalAmount", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2F6A3E))),
            ],
          ),
          if (onApprove != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Approve"),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _primaryAddressLine(Map<String, dynamic> address) {
    final fullAddress = address['fullAddress']?.toString().trim() ?? '';
    final landmark = address['landmark']?.toString().trim() ?? '';
    final city = address['city']?.toString().trim() ?? '';

    final lower = fullAddress.toLowerCase();
    final looksLikeLatLng = lower.contains('latitude:') || lower.contains('longitude:');

    if (looksLikeLatLng || fullAddress.isEmpty) {
      if (landmark.isNotEmpty && !_isGenericCurrentLocation(landmark)) {
        return landmark;
      }
      if (city.isNotEmpty && !_isGenericCurrentLocation(city)) {
        return city;
      }
      return currentLocationLabel;
    }

    return fullAddress;
  }

  String _secondaryAddressLine(Map<String, dynamic> address) {
    final city = address['city']?.toString().trim() ?? '';
    final pincode = address['pincode']?.toString().trim() ?? '';

    if (city.isEmpty && pincode.isEmpty) {
      return '';
    }
    if (city.isEmpty) {
      return pincode;
    }
    if (pincode.isEmpty) {
      return city;
    }
    return '$city - $pincode';
  }

  bool _isGenericCurrentLocation(String value) {
    final normalized = value.trim().toLowerCase();
    final normalizedL10n = currentLocationLabel.trim().toLowerCase();
    return normalized == 'current location' || normalized == normalizedL10n;
  }

  Future<List<String>> _resolveAddressLines(Map<String, dynamic> address) async {
    final fullAddress = address['fullAddress']?.toString().trim() ?? '';
    final match = RegExp(
      r'Latitude:\s*([\-0-9.]+)\s*,\s*Longitude:\s*([\-0-9.]+)',
      caseSensitive: false,
    ).firstMatch(fullAddress);

    if (match == null) {
      return <String>[
        _primaryAddressLine(address),
        _secondaryAddressLine(address),
      ];
    }

    final lat = double.tryParse(match.group(1) ?? '');
    final lng = double.tryParse(match.group(2) ?? '');
    if (lat == null || lng == null) {
      return <String>[
        _primaryAddressLine(address),
        _secondaryAddressLine(address),
      ];
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return <String>[
          _primaryAddressLine(address),
          _secondaryAddressLine(address),
        ];
      }

      final p = placemarks.first;
      final primary = [
        p.subLocality,
        p.street,
        p.name,
      ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

      final city = (p.locality?.trim().isNotEmpty == true)
          ? p.locality!
          : (p.administrativeArea ?? '');
      final pincode = p.postalCode ?? '';
      final secondary =
          [city, pincode].where((part) => part.trim().isNotEmpty).join(' - ');

      return <String>[
        primary.isNotEmpty ? primary : _primaryAddressLine(address),
        secondary.isNotEmpty ? secondary : _secondaryAddressLine(address),
      ];
    } catch (_) {
      return <String>[
        _primaryAddressLine(address),
        _secondaryAddressLine(address),
      ];
    }
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
