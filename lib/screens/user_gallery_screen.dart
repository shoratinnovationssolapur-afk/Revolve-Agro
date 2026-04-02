import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
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
    final l10n = context.l10n;
    return Scaffold(
      body: AppShell(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: AppPageHeader(
                  title: l10n.text('gallery_title'),
                  subtitle: l10n.text('gallery_subtitle'),
                  badgeIcon: Icons.photo_library_outlined,
                  leading: const _GalleryBackButton(),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('gallery')
                      .orderBy('uploadedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF2F6A3E)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.perm_media_outlined,
                        title: l10n.text('no_memories_title'),
                        subtitle: l10n.text('no_memories_subtitle'),
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
                        final media = snapshot.data!.docs[index];
                        final payload = media.data();
                        final url = payload['url']?.toString() ?? '';
                        final type = payload['type']?.toString() ?? 'image';
                        final productName = payload['productName']?.toString() ?? '';
                        final description = payload['description']?.toString() ?? '';

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
                              color: Colors.white.withOpacity(0.94),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 10),
                                ),
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
                                        color: Colors.white,
                                        size: 52,
                                      ),
                                    ),
                                  if (productName.isNotEmpty || description.isNotEmpty)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.72),
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (productName.isNotEmpty)
                                              Text(
                                                productName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            if (description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  height: 1.3,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
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

class _GalleryBackButton extends StatelessWidget {
  const _GalleryBackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}
