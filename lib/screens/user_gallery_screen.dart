import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'full_screen_viewer.dart';

class UserGalleryScreen extends StatelessWidget {
  const UserGalleryScreen({super.key});

  // Helper to generate a thumbnail URL from a Cloudinary video URL
  String _getThumbnail(String url, String type) {
    if (type == 'video') {
      // Replaces .mp4 with .jpg so Cloudinary serves a preview frame
      return url.replaceAll('.mp4', '.jpg').replaceAll('.mov', '.jpg').replaceAll('.mkv', '.jpg');
    }
    return url;
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
              // 🔥 HEADER (MATCH APP DESIGN)
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
                        style: IconButton.styleFrom(backgroundColor: Colors.white24),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Gallery",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔥 LIVE GRID FROM FIRESTORE
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('gallery')
                      .orderBy('uploadedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF2F6A3E)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No memories shared yet.", style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: snapshot.data!.docs.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        var media = snapshot.data!.docs[index];
                        String url = media['url'];
                        String type = media['type'];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenViewer(
                                  url: url,
                                  type: type,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Shows actual image or generated video thumbnail
                                  Image.network(
                                    _getThumbnail(url, type),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, e, s) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                  if (type == 'video')
                                    const Center(
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white70,
                                        size: 45,
                                      ),
                                    ),
                                ],
                              ),
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