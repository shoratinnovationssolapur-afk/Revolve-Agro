import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InquiryService {
  static CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('inquiries');

  static Future<void> submit({
    required String name,
    required String email,
    required String subject,
    required String message,
    String? phone,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No logged-in user');
    }

    final trimmedPhone = phone?.trim();

    // Explicitly using a Map to ensure userId is present for security rules
    await _collection.add({
      'userId': user.uid,
      'name': name.trim(),
      'email': email.trim(),
      'phone': trimmedPhone ?? '',
      'subject': subject.trim(),
      'message': message.trim(),
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> stream({
    String? status,
    String? userId,
  }) {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('inquiries').orderBy(
              'createdAt',
              descending: true,
            );

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    final trimmed = status?.trim();
    if (trimmed != null && trimmed.isNotEmpty && trimmed != 'all') {
      query = query.where('status', isEqualTo: trimmed);
    }

    return query.snapshots();
  }

  static Future<void> markRead(String inquiryId) async {
    await _collection.doc(inquiryId).set(
      {
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> delete(String inquiryId) async {
    await _collection.doc(inquiryId).delete();
  }
}
