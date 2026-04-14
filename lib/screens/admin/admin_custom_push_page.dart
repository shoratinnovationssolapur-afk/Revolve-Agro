import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminCustomPushPage extends StatefulWidget {
  const AdminCustomPushPage({super.key});

  @override
  State<AdminCustomPushPage> createState() => _AdminCustomPushPageState();
}

class _AdminCustomPushPageState extends State<AdminCustomPushPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageController = TextEditingController();
  String _selectedStyle = 'simple'; // Options: simple, paragraph, banner
  bool _isLoading = false;

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and Body are required")),
      );
      return;
    }

    setState(() => _isLoading = true);

    const String url = "https://revolve-agro-backend.onrender.com/send-agro-notification";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "title": _titleController.text,
          "body": _bodyController.text,
          "image": (_selectedStyle != 'simple') ? _imageController.text : null,
          "topic": "all_members",
          "type": _selectedStyle, // Passing the type so app can handle UI
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification sent successfully!")),
        );
        _titleController.clear();
        _bodyController.clear();
        _imageController.clear();
      } else {
        throw Exception("Failed to send");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Broadcast Notifications"),
        backgroundColor: const Color(0xFF183020),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Style", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // STYLE SELECTOR
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'simple', label: Text('Simple'), icon: Icon(Icons.short_text)),
                ButtonSegment(value: 'paragraph', label: Text('Paragraph'), icon: Icon(Icons.notes)),
                ButtonSegment(value: 'banner', label: Text('Banner'), icon: Icon(Icons.image)),
              ],
              selected: {_selectedStyle},
              onSelectionChanged: (val) => setState(() => _selectedStyle = val.first),
            ),

            const SizedBox(height: 25),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
                hintText: "e.g., New Stock Arrival!",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bodyController,
              maxLines: _selectedStyle == 'paragraph' ? 5 : 2,
              decoration: const InputDecoration(
                labelText: "Message Body",
                border: OutlineInputBorder(),
                hintText: "Enter the notification details here...",
              ),
            ),

            if (_selectedStyle != 'simple') ...[
              const SizedBox(height: 20),
              TextField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: "Image URL",
                  border: OutlineInputBorder(),
                  hintText: "Paste image link from Firebase/Cloudinary",
                  prefixIcon: Icon(Icons.link),
                ),
              ),
            ],

            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF183020),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.send_rounded),
                label: const Text("SEND NOTIFICATION", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}