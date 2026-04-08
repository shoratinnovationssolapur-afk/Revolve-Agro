import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrderManagementService {
  /// Approve multiple orders at once (bulk action)
  static Future<int> bulkApproveOrders(List<String> orderIds) async {
    int successCount = 0;
    final batch = FirebaseFirestore.instance.batch();
    final timestamp = DateTime.now();

    for (final orderId in orderIds) {
      try {
        final orderRef = FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId);
        final orderDoc = await orderRef.get();
        
        if (!orderDoc.exists) continue;

        final orderData = orderDoc.data() as Map<String, dynamic>;
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

        successCount++;
      } catch (e) {
        print('Error processing order $orderId: $e');
      }
    }

    if (successCount > 0) {
      await batch.commit();
    }
    return successCount;
  }

  /// Reject multiple orders at once (bulk action)
  static Future<int> bulkRejectOrders(
    List<String> orderIds,
    String rejectionReason,
  ) async {
    int successCount = 0;
    final batch = FirebaseFirestore.instance.batch();
    final timestamp = DateTime.now();

    for (final orderId in orderIds) {
      try {
        final orderRef = FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId);
        final orderDoc = await orderRef.get();
        
        if (!orderDoc.exists) continue;

        final orderData = orderDoc.data() as Map<String, dynamic>;
        final statusHistory = (orderData['statusHistory'] as List?) ?? [];

        statusHistory.add({
          'status': 'rejected',
          'timestamp': timestamp,
          'reason': rejectionReason,
        });

        batch.update(orderRef, {
          'status': 'rejected',
          'rejectionReason': rejectionReason,
          'updatedAt': timestamp,
          'statusHistory': statusHistory,
        });

        successCount++;
      } catch (e) {
        print('Error processing order $orderId: $e');
      }
    }

    if (successCount > 0) {
      await batch.commit();
    }
    return successCount;
  }

  /// Get pending orders count
  static Future<int> getPendingOrdersCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting pending orders count: $e');
      return 0;
    }
  }

  /// Get orders by date range
  static Stream<QuerySnapshot> getOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
    String? statusFilter,
  ) {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: endDate);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }

  /// Get order statistics
  static Future<Map<String, int>> getOrderStatistics() async {
    try {
      final pendingSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final approvedSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'approved')
          .count()
          .get();

      final rejectedSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'rejected')
          .count()
          .get();

      return {
        'pending': pendingSnap.count ?? 0,
        'approved': approvedSnap.count ?? 0,
        'rejected': rejectedSnap.count ?? 0,
        'total': (pendingSnap.count ?? 0) +
            (approvedSnap.count ?? 0) +
            (rejectedSnap.count ?? 0),
      };
    } catch (e) {
      print('Error getting order statistics: $e');
      return {'pending': 0, 'approved': 0, 'rejected': 0, 'total': 0};
    }
  }
}
