import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  // Using Firebase Cloud Functions endpoint for sending emails
  // You need to set up Cloud Functions with nodemailer or similar service
  static const String _cloudFunctionUrl =
      'https://us-central1-revolveagro-xxxxx.cloudfunctions.net/sendOrderEmail';

  // Alternative: Using EmailJS or similar service
  static const String _emailJsUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Send order approval notification email
  static Future<void> sendOrderApprovalEmail({
    required String userEmail,
    required String userName,
    required String orderId,
    required double totalAmount,
  }) async {
    try {
      final emailContent = '''
Dear $userName,

Great news! Your order #$orderId has been approved.

Order Details:
- Order ID: $orderId
- Total Amount: \$$totalAmount
- Status: APPROVED

Your order will be processed and delivered soon. We will keep you updated on the delivery status.

Thank you for using Revolve Agro!

Best regards,
Revolve Agro Team
      ''';

      await _sendEmail(
        recipientEmail: userEmail,
        recipientName: userName,
        subject: 'Order #$orderId Approved - Revolve Agro',
        body: emailContent,
        status: 'approved',
      );
    } catch (e) {
      print('Error sending approval email: $e');
      // Don't throw - email failure shouldn't prevent order approval
    }
  }

  /// Send order rejection notification email
  static Future<void> sendOrderRejectionEmail({
    required String userEmail,
    required String userName,
    required String orderId,
    required double totalAmount,
    required String rejectionReason,
  }) async {
    try {
      final emailContent = '''
Dear $userName,

Unfortunately, your order #$orderId could not be approved.

Order Details:
- Order ID: $orderId
- Total Amount: \$$totalAmount
- Status: REJECTED

Reason for Rejection:
$rejectionReason

If you have any questions or would like to place a new order, please contact us.

Thank you for understanding.

Best regards,
Revolve Agro Team
      ''';

      await _sendEmail(
        recipientEmail: userEmail,
        recipientName: userName,
        subject: 'Order #$orderId Rejected - Revolve Agro',
        body: emailContent,
        status: 'rejected',
      );
    } catch (e) {
      print('Error sending rejection email: $e');
    }
  }

  /// Generic email sending function
  static Future<void> _sendEmail({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String body,
    required String status,
  }) async {
    try {
      // Store email in Firestore for Cloud Functions to process
      await FirebaseFirestore.instance.collection('emails').add({
        'to': recipientEmail,
        'message': {
          'subject': subject,
          'text': body,
        },
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });
    } catch (e) {
      print('Error queuing email: $e');
      rethrow;
    }
  }

  /// Alternative method using direct HTTP request (if you have backend)
  static Future<void> sendEmailViaBackend({
    required String userEmail,
    required String userName,
    required String orderId,
    required String status,
    required String? rejectionReason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-backend-url/send-order-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': userEmail,
          'name': userName,
          'orderId': orderId,
          'status': status,
          'rejectionReason': rejectionReason,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        print('Email sending failed: ${response.body}');
      }
    } catch (e) {
      print('Error sending email via backend: $e');
    }
  }
}
