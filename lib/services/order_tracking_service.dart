import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTrackingService {
  static const List<String> trackingStatuses = [
    'processing',
    'shipped',
    'delivered',
  ];

  /// Update tracking status for an order
  static Future<void> updateTrackingStatus({
    required String orderId,
    required String newStatus,
    String? trackingNumber,
    String? notes,
  }) async {
    if (!trackingStatuses.contains(newStatus)) {
      throw Exception('Invalid tracking status: $newStatus');
    }

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
            'trackingStatus': newStatus,
            'trackingUpdatedAt': DateTime.now(),
            if (trackingNumber != null) 'trackingNumber': trackingNumber,
            if (notes != null) 'trackingNotes': notes,
          });
    } catch (e) {
      throw Exception('Failed to update tracking status: $e');
    }
  }

  /// Get tracking details for an order
  static Future<Map<String, dynamic>?> getTrackingDetails(
      String orderId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>?;
      return {
        'status': data?['trackingStatus'] ?? 'none',
        'trackingNumber': data?['trackingNumber'],
        'notes': data?['trackingNotes'],
        'updatedAt': data?['trackingUpdatedAt'],
      };
    } catch (e) {
      print('Error fetching tracking details: $e');
      return null;
    }
  }

  /// Get tracking history for an order
  static Future<List<Map<String, dynamic>>> getTrackingHistory(
      String orderId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!doc.exists) return [];

      final data = doc.data() as Map<String, dynamic>?;
      final history = data?['statusHistory'] as List? ?? [];

      return history
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      print('Error fetching tracking history: $e');
      return [];
    }
  }
}
