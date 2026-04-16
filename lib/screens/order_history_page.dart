import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import '../widgets/app_shell.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> with TickerProviderStateMixin {
  String _selectedFilter = 'all'; 
  late final AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return AppShell(
      backgroundImage: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?q=80&w=2064&auto=format&fit=crop',
      overlayOpacity: 0.5,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: user == null
                  ? const Center(child: Text('Please log in to see your orders', style: TextStyle(color: Colors.white)))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _buildOrdersStream(user.uid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                        final docs = _filterOrders(snapshot.data?.docs ?? const []);
                        if (docs.isEmpty) return _buildEmptyState();

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final anim = CurvedAnimation(parent: _listController, curve: Interval((index / docs.length).clamp(0, 1), 1.0, curve: Curves.easeOut));
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim),
                                child: OrderStatusCard(id: docs[index].id, data: docs[index].data() as Map<String, dynamic>),
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
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Row(
        children: [
          IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1))),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('Track your farm supplies', style: TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['all', 'pending', 'approved', 'rejected'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.toUpperCase(), style: TextStyle(color: _selectedFilter == f ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
              selected: _selectedFilter == f,
              onSelected: (_) => setState(() => _selectedFilter = f),
              backgroundColor: Colors.white.withOpacity(0.05),
              selectedColor: const Color(0xFF7BB960),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              showCheckmark: false,
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_rounded, size: 64, color: Colors.white.withOpacity(0.3)),
        const SizedBox(height: 16),
        const Text('No orders found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Stream<QuerySnapshot> _buildOrdersStream(String userId) {
    return FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: userId).orderBy('timestamp', descending: true).snapshots();
  }

  List<QueryDocumentSnapshot> _filterOrders(List<QueryDocumentSnapshot> docs) {
    if (_selectedFilter == 'all') return docs;
    return docs.where((doc) => (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase() == _selectedFilter).toList();
  }
}

class OrderStatusCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  const OrderStatusCard({super.key, required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status']?.toString().toLowerCase() ?? 'pending';
    final amount = data['totalAmount']?.toString() ?? '0';
    final date = (data['timestamp'] as Timestamp?)?.toDate();
    final Color statusColor = status == 'approved' ? const Color(0xFF7BB960) : status == 'rejected' ? Colors.redAccent : Colors.orangeAccent;

    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      color: Colors.white.withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #...${id.substring(id.length - 6)}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('₹$amount', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                if (date != null) Text('${date.day}/${date.month}/${date.year}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ])),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
