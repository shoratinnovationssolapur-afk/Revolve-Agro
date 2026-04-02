import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart'; // Ensure this file exists with the logic we discussed

class AdminGalleryScreen extends StatefulWidget {
  const AdminGalleryScreen({super.key});

  @override
  State<AdminGalleryScreen> createState() => _AdminGalleryScreenState();
}

class _AdminGalleryScreenState extends State<AdminGalleryScreen> {
  final ImagePicker picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isUploading = false;

  // Function to handle the actual upload logic
  Future<void> _handleUpload(File file, String type) async {
    setState(() => _isUploading = true);

    try {
      // 1. Upload to Cloudinary using the dynamic service we built
      String? url = await _cloudinaryService.uploadMedia(file, type);

      if (url != null) {
        // 2. Save to Firestore 'gallery' collection
        await FirebaseFirestore.instance.collection('gallery').add({
          'url': url,
          'type': type,
          'uploadedAt': FieldValue.serverTimestamp(),
          'name': file.path.split('/').last, // Keep original filename for reference
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${type[0].toUpperCase()}${type.substring(1)} uploaded successfully!")),
          );
        }
      } else {
        throw Exception("Cloudinary upload failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _handleUpload(File(image.path), "image");
    }
  }

  Future<void> pickVideo() async {
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      await _handleUpload(File(video.path), "video");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF3DE), Color(0xFFF7F3E8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔥 HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF183020), Color(0xFF30523B)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Admin Gallery",
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      if (_isUploading)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),

              // 🔥 UPLOAD BUTTONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text("Image"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F6A3E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : pickVideo,
                        icon: const Icon(Icons.video_library),
                        label: const Text("Video"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD9952E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 🔥 LIVE GALLERY GRID FROM FIRESTORE
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('gallery')
                      .orderBy('uploadedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No media in gallery"));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(18),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var media = snapshot.data!.docs[index];
                        bool isVideo = media['type'] == 'video';

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  // For videos, Cloudinary can generate a thumbnail by changing extension to .jpg
                                  isVideo
                                      ? media['url'].replaceAll('.mp4', '.jpg').replaceAll('.mov', '.jpg')
                                      : media['url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, e, s) => Container(
                                    color: Colors.grey[300],
                                    child: Icon(isVideo ? Icons.videocam : Icons.image, color: Colors.grey),
                                  ),
                                ),
                                if (isVideo)
                                  const Center(
                                    child: Icon(Icons.play_circle_fill, color: Colors.white, size: 45),
                                  ),
                              ],
                            ),
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
}