import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
// lib/services/notification_service.dart
  static const String _url = "https://revolve-agro-backend.onrender.com/send-agro-notification";

  static Future<bool> sendCustomPush({
    required String title,
    required String body,
    String? imageUrl,
    required String styleType, // 'simple', 'paragraph', 'banner'
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "title": title,
          "body": body,
          "image": imageUrl,
          "topic": "all_members",
          "type": styleType, // 🔥 Moved to top level to match Python backend 'body.get("type")'
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Push Error: $e");
      return false;
    }
  }
}