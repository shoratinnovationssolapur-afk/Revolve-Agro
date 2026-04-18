import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../cloudinary_service.dart'; // Ensure this path is correct

class AdminCustomPushPage extends StatefulWidget {
  const AdminCustomPushPage({super.key});

  @override
  State<AdminCustomPushPage> createState() => _AdminCustomPushPageState();
}

class _AdminCustomPushPageState extends State<AdminCustomPushPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  String _selectedStyle = 'simple'; 
  bool _isLoading = false;
  bool _isUploadingImage = false;

  /// Pick and Upload image to Cloudinary, then set the URL to the controller
  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      String? uploadedUrl = await _cloudinaryService.uploadMedia(File(image.path), "image");
      if (uploadedUrl != null) {
        setState(() {
          _imageController.text = uploadedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image uploaded and linked!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

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
      final Map<String, dynamic> notificationData = {
        "title": _titleController.text,
        "body": _bodyController.text,
        "image": (_selectedStyle != 'simple') ? _imageController.text : null,
        "topic": "all_members",
        "type": _selectedStyle,
      };

      // 1. Send via Backend API
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(notificationData),
      );

      if (response.statusCode == 200) {
        // 2. Save to Firestore 'notifications' collection for history
        await FirebaseFirestore.instance.collection('notifications').add({
          ...notificationData,
          'sentAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Notification sent successfully!")),
          );
          _titleController.clear();
          _bodyController.clear();
          _imageController.clear();
        }
      } else {
        throw Exception("Failed to send: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'simple', label: Text('Simple'), icon: Icon(Icons.short_text)),
                ButtonSegment(value: 'paragraph', label: Text('Para'), icon: Icon(Icons.notes)),
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
                hintText: "Enter details here...",
              ),
            ),

            // Image Section (Visible for Paragraph and Banner styles)
            if (_selectedStyle != 'simple') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _imageController,
                      decoration: const InputDecoration(
                        labelText: "Image URL",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 57,
                    child: ElevatedButton(
                      onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isUploadingImage 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_file),
                    ),
                  ),
                ],
              ),
              if (_imageController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_imageController.text, height: 100, fit: BoxFit.cover),
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