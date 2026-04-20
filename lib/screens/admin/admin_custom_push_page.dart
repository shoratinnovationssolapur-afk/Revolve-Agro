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
  // Controllers
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageController = TextEditingController();

  // Services
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // State Variables
  String _selectedStyle = 'simple';
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  /// Handles picking an image from gallery and uploading to Cloudinary
  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      // Upload using your custom Cloudinary service
      String? uploadedUrl = await _cloudinaryService.uploadMedia(File(image.path), "image");

      if (uploadedUrl != null) {
        setState(() {
          _imageController.text = uploadedUrl;
        });
        _showSnackBar("Image uploaded and linked!", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Upload failed: $e", Colors.red);
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  /// Sends the notification via Backend and saves to Firestore
  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      _showSnackBar("Title and Body are required", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    const String url = "https://revolve-agro-backend.onrender.com/send-agro-notification";

    try {
      final Map<String, dynamic> notificationData = {
        "title": _titleController.text.trim(),
        "body": _bodyController.text.trim(),
        "image": (_selectedStyle != 'simple') ? _imageController.text.trim() : null,
        "topic": "all_members",
        "type": _selectedStyle,
      };

      // 1. Hit the Backend API to trigger FCM
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(notificationData),
      );

      if (response.statusCode == 200) {
        // 2. Log the notification in Firestore history
        await FirebaseFirestore.instance.collection('notifications').add({
          ...notificationData,
          'sentAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          _showSnackBar("Notification sent successfully!", Colors.green);
          _clearForm();
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _bodyController.clear();
    _imageController.clear();
    setState(() => _selectedStyle = 'simple');
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF183020);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Broadcast Notifications"),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Style", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            // STYLE SELECTOR
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'simple', label: Text('Simple'), icon: Icon(Icons.short_text)),
                  ButtonSegment(value: 'paragraph', label: Text('Para'), icon: Icon(Icons.notes)),
                  ButtonSegment(value: 'banner', label: Text('Banner'), icon: Icon(Icons.image)),
                ],
                selected: {_selectedStyle},
                onSelectionChanged: (val) => setState(() => _selectedStyle = val.first),
              ),
            ),

            const SizedBox(height: 25),

            // TITLE INPUT
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Notification Title",
                border: OutlineInputBorder(),
                hintText: "e.g., New Stock Arrival!",
              ),
            ),

            const SizedBox(height: 20),

            // BODY INPUT
            TextField(
              controller: _bodyController,
              maxLines: _selectedStyle == 'paragraph' ? 5 : 2,
              decoration: const InputDecoration(
                labelText: "Message Body",
                border: OutlineInputBorder(),
                hintText: "Enter details here...",
              ),
            ),

            // IMAGE SECTION (Conditional)
            if (_selectedStyle != 'simple') ...[
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _imageController,
                      decoration: const InputDecoration(
                        labelText: "Image URL",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                        hintText: "https://...",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isUploadingImage
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_outlined),
                    ),
                  ),
                ],
              ),
              if (_imageController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _imageController.text,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Text("Invalid image URL"),
                        ),
                      ),
                      Positioned(
                        right: 5,
                        top: 5,
                        child: CircleAvatar(
                          backgroundColor: Colors.white70,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => _imageController.clear()),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 40),

            // SEND BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Icon(Icons.send_rounded),
                label: const Text(
                    "SEND NOTIFICATION",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}