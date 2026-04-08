import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import '../widgets/gallery_media_card.dart';
import 'full_screen_viewer.dart';

class UserGalleryScreen extends StatelessWidget {
  const UserGalleryScreen({super.key});

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

                    return ListView.separated(
                      padding: const EdgeInsets.all(18),
                      itemCount: snapshot.data!.docs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        final media = snapshot.data!.docs[index];
                        final payload = media.data();
                        final url = payload['url']?.toString() ?? '';
                        final type = payload['type']?.toString() ?? 'image';
                        final productName = payload['productName']?.toString() ?? '';
                        final description = payload['description']?.toString() ?? '';

                        return GalleryMediaCard(
                          url: url,
                          type: type,
                          title: productName,
                          description: description,
                          onOpen: () {
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
