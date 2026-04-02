import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import 'full_screen_viewer.dart';
import 'product_list.dart';
import 'profile_page.dart';
import 'user_gallery_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  static const List<_QuickModule> _quickModules = [
    _QuickModule(
      title: 'Shop Inputs',
      subtitle: 'Seeds, nutrition, and crop care',
      icon: Icons.storefront_outlined,
      color: Color(0xFF2F6A3E),
      destinationIndex: 1,
    ),
    _QuickModule(
      title: 'My Cart',
      subtitle: 'Checkout your current order',
      icon: Icons.shopping_cart_checkout_outlined,
      color: Color(0xFFD9952E),
      destinationIndex: 2,
    ),
    _QuickModule(
      title: 'Profile',
      subtitle: 'Language and account settings',
      icon: Icons.person_outline_rounded,
      color: Color(0xFF305C89),
      destinationIndex: 3,
    ),
    _QuickModule(
      title: 'Crop Feed',
      subtitle: 'Fresh product stories and updates',
      icon: Icons.campaign_outlined,
      color: Color(0xFF8C5B1C),
      destinationIndex: 0,
    ),
  ];

  static const List<_InsightCardData> _insights = [
    _InsightCardData(
      title: 'Field-ready guidance',
      subtitle: 'See solutions by crop health, soil nutrition, and stage of growth.',
      icon: Icons.eco_outlined,
      tint: Color(0xFFE7F2DE),
    ),
    _InsightCardData(
      title: 'Faster buying decisions',
      subtitle: 'Compare trusted farm products in one place and move to checkout quickly.',
      icon: Icons.bolt_outlined,
      tint: Color(0xFFF8E8C8),
    ),
    _InsightCardData(
      title: 'Farmer-first experience',
      subtitle: 'Simple sections, local language support, and practical navigation.',
      icon: Icons.forum_outlined,
      tint: Color(0xFFE3EEF8),
    ),
  ];

  int _currentIndex = 0;
  String userName = '';
  String location = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) {
      return;
    }

    setState(() {
      userName = doc.data()?['name']?.toString() ?? context.l10n.text('farmer');
      location = _resolveLocationLabel(doc.data());
    });
  }

  String _resolveLocationLabel(Map<String, dynamic>? data) {
    if (data == null) {
      return context.l10n.text('current_location_fallback');
    }

    final city = data['city']?.toString().trim() ?? '';
    final landmark = data['landmark']?.toString().trim() ?? '';
    final fullAddress = data['fullAddress']?.toString().trim() ?? '';

    if (city.isNotEmpty) {
      return city;
    }

    if (landmark.isNotEmpty) {
      return landmark.split(',').first.trim();
    }

    if (fullAddress.isNotEmpty) {
      return fullAddress.split(',').first.trim();
    }

    return context.l10n.text('current_location_fallback');
  }

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _openCartOrShowMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.text('no_items_added_cart'))),
    );
  }

  Widget _buildHome() {
    final l10n = context.l10n;
    return AppShell(
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppPageHeader(
                      title: l10n.textWithArgs(
                        'hello_user',
                        {'name': userName.isEmpty ? l10n.text('farmer') : userName},
                      ),
                      subtitle: l10n.text('dashboard_subtitle'),
                      badgeIcon: Icons.agriculture_outlined,
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              location.isEmpty ? l10n.text('current_location_fallback') : location,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        IconButton.filledTonal(
                          onPressed: () => _goToTab(3),
                          icon: const Icon(Icons.person_outline_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AppGlassCard(
                      child: LayoutBuilder(
                        builder: (context, boxConstraints) {
                          final isCompact = boxConstraints.maxWidth < 360;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.text('quick_actions'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF183020),
                                ),
                              ),
                              const SizedBox(height: 14),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _quickModules.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: isCompact ? 0.96 : 1.08,
                                ),
                                itemBuilder: (context, index) {
                                  final module = _quickModules[index];
                                  return _DashboardModuleCard(
                                    module: module,
                                    onTap: () => _goToTab(module.destinationIndex),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.text('why_app_better'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF183020),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ..._insights.map(
                            (insight) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _InsightCard(insight: insight),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AppSectionHeading(
                            title: l10n.text('gallery_highlights'),
                            subtitle: l10n.text('gallery_highlights_subtitle'),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserGalleryScreen(),
                              ),
                            );
                          },
                          child: Text(l10n.text('open_gallery')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('gallery')
                  .orderBy('uploadedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF2F6A3E)),
                    ),
                  );
                }

                final items = snapshot.data!.docs;
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.photo_library_outlined,
                      title: l10n.text('no_gallery_images'),
                      subtitle: l10n.text('no_gallery_images_subtitle'),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final data = items[index];
                        final payload = data.data();
                        final url = payload['url']?.toString() ?? '';
                        final type = payload['type']?.toString() ?? 'image';
                        final productName = payload['productName']?.toString() ?? '';
                        final description = payload['description']?.toString() ?? '';

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
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
                            borderRadius: BorderRadius.circular(24),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.94),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      _thumbnailFor(url, type),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: const Color(0xFFE8E1D5),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.image_not_supported_outlined, size: 36),
                                      ),
                                    ),
                                    if (type == 'video')
                                      const Center(
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white,
                                          size: 48,
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
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _thumbnailFor(String url, String type) {
    if (type == 'video') {
      return url.replaceAll('.mp4', '.jpg').replaceAll('.mov', '.jpg').replaceAll('.mkv', '.jpg');
    }
    return url;
  }

  Widget _buildCart() {
    final l10n = context.l10n;
    return AppShell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeading(
                title: l10n.text('cart_checkout_title'),
                subtitle: l10n.text('cart_checkout_subtitle'),
              ),
              const SizedBox(height: 18),
              AppEmptyState(
                icon: Icons.shopping_cart_checkout_outlined,
                title: l10n.text('checkout_center'),
                subtitle: l10n.text('checkout_center_subtitle'),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  _openCartOrShowMessage();
                },
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(l10n.text('go_to_cart')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProducts() {
    return const RevolveAgroProducts();
  }

  Widget _buildProfile() {
    return const ProfilePage(role: 'User');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      _buildHome(),
      _buildProducts(),
      _buildCart(),
      _buildProfile(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        height: 76,
        indicatorColor: const Color(0xFFE2F0D8),
        backgroundColor: Colors.white,
        onDestinationSelected: _goToTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.text('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront_rounded),
            label: l10n.text('shop'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart_rounded),
            label: l10n.text('my_cart'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l10n.text('profile_short'),
          ),
        ],
      ),
    );
  }
}

class _DashboardModuleCard extends StatelessWidget {
  final _QuickModule module;
  final VoidCallback onTap;

  const _DashboardModuleCard({
    required this.module,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titleKey = _titleKeyForDestination(module.destinationIndex);
    final subtitleKey = _subtitleKeyForDestination(module.destinationIndex);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: module.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: module.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(module.icon, color: module.color),
              ),
              const Spacer(),
              Text(
                l10n.text(titleKey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF183020),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.text(subtitleKey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleKeyForDestination(int destinationIndex) {
    if (destinationIndex == 1) {
      return 'shop_inputs';
    }
    if (destinationIndex == 2) {
      return 'my_cart';
    }
    if (destinationIndex == 3) {
      return 'profile_short';
    }
    return 'crop_feed';
  }

  String _subtitleKeyForDestination(int destinationIndex) {
    if (destinationIndex == 1) {
      return 'shop_inputs_subtitle';
    }
    if (destinationIndex == 2) {
      return 'my_cart_subtitle';
    }
    if (destinationIndex == 3) {
      return 'profile_short_subtitle';
    }
    return 'crop_feed_subtitle';
  }
}

class _InsightCard extends StatelessWidget {
  final _InsightCardData insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titleKey = _titleKeyForInsight(insight.icon);
    final subtitleKey = _subtitleKeyForInsight(insight.icon);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.tint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(insight.icon, color: const Color(0xFF214B2D)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.text(titleKey),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183020),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.text(subtitleKey),
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleKeyForInsight(IconData icon) {
    if (icon == Icons.eco_outlined) {
      return 'field_ready_guidance';
    }
    if (icon == Icons.bolt_outlined) {
      return 'faster_buying_decisions';
    }
    return 'farmer_first_experience';
  }

  String _subtitleKeyForInsight(IconData icon) {
    if (icon == Icons.eco_outlined) {
      return 'field_ready_guidance_subtitle';
    }
    if (icon == Icons.bolt_outlined) {
      return 'faster_buying_decisions_subtitle';
    }
    return 'farmer_first_experience_subtitle';
  }
}

class _QuickModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int destinationIndex;

  const _QuickModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.destinationIndex,
  });
}

class _InsightCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;

  const _InsightCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
  });
}
