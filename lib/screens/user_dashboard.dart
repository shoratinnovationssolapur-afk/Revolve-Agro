import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import '../widgets/gallery_media_card.dart';
import '../widgets/language_selector.dart';
import '../utils/helpline.dart';
import 'full_screen_viewer.dart';
import 'order_history_page.dart';
import 'product_list.dart';
import 'profile_page.dart';
import 'user_gallery_screen.dart';
import 'query_form_page.dart';
import 'user_inquiries_page.dart'; // Added import

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> with TickerProviderStateMixin {
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
      title: 'Order History',
      subtitle: 'Track your order status',
      icon: Icons.history_outlined,
      color: Color(0xFF8B5CF6),
      destinationIndex: 4,
    ),
    _QuickModule(
      title: 'Profile',
      subtitle: 'Language and account settings',
      icon: Icons.person_outline_rounded,
      color: Color(0xFF305C89),
      destinationIndex: 3,
    ),
    _QuickModule(
      title: 'Support Queries',
      subtitle: 'Ask questions and get help',
      icon: Icons.forum_outlined,
      color: Color(0xFF183020),
      destinationIndex: 5,
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
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setFallbackLocation();
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() => location = placemark.locality ?? 'Current Location');
      }
    } catch (e) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
        if (mounted && location.isEmpty) {
          setState(() => location = doc.data()?['city']?.toString() ?? 'Current Location');
        }
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (mounted) setState(() => userName = doc.data()?['name']?.toString() ?? 'Farmer');
  }

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _showSupportMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF183020).withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Text('Support Center', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _supportOption(
              icon: Icons.edit_note_rounded,
              title: 'Ask a New Question',
              subtitle: 'Send a message to our agri-experts',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QueryFormPage()));
              },
            ),
            const SizedBox(height: 16),
            _supportOption(
              icon: Icons.history_edu_rounded,
              title: 'View My History',
              subtitle: 'See your past inquiries and replies',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UserInquiriesPage()));
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _supportOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white12)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF7BB960).withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF7BB960))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            ])),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      _buildHome(),
      _buildShop(),
      _buildCart(),
      const ProfilePage(role: 'User'),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: _buildModernNavBar(),
    );
  }

  Widget _buildModernNavBar() {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFF183020).withOpacity(0.92),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.home_outlined, Icons.home_rounded, 0, l10n.text('home')),
          _navItem(Icons.storefront_outlined, Icons.storefront_rounded, 1, l10n.text('shop')),
          _navItem(Icons.shopping_cart_outlined, Icons.shopping_cart_rounded, 2, l10n.text('my_cart')),
          _navItem(Icons.person_outline_rounded, Icons.person_rounded, 3, l10n.text('profile_short')),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, int index, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _goToTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7BB960).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF7BB960) : Colors.white.withOpacity(0.7),
              size: 26,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 4,
                width: 4,
                decoration: const BoxDecoration(color: Color(0xFF7BB960), shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    final l10n = context.l10n;
    return AppShell(
      backgroundImage: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?q=80&w=2064&auto=format&fit=crop',
      overlayOpacity: 0.25,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                title: l10n.textWithArgs('hello_user', {'name': userName.isEmpty ? l10n.text('farmer') : userName}),
                subtitle: l10n.text('dashboard_subtitle'),
                badgeIcon: Icons.agriculture_outlined,
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(location.isEmpty ? l10n.text('current_location_fallback') : location, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _getCurrentLocation,
                        child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
                actions: [
                  const LanguageSelector(),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(onPressed: () => openHelplineWhatsApp(context), icon: const Icon(Icons.support_agent_rounded)),
                  IconButton.filledTonal(onPressed: () => _goToTab(3), icon: const Icon(Icons.person_outline_rounded)),
                ],
              ),
              const SizedBox(height: 24),
              AppSectionHeading(title: l10n.text('quick_actions'), color: Colors.white),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _quickModules.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final module = _quickModules[index];
                  return _DashboardCreativeCard(
                    module: module,
                    onTap: () {
                      if (module.destinationIndex == 4) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryPage()));
                      } else if (module.destinationIndex == 5) {
                        _showSupportMenu(); // Fixed: Now shows the choice menu
                      } else {
                        _goToTab(module.destinationIndex);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
              AppGlassCard(
                color: Colors.white.withOpacity(0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.text('why_app_better'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 18),
                    ..._insights.map((insight) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _InsightCreativeCard(insight: insight))),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppSectionHeading(title: l10n.text('gallery_highlights'), color: Colors.white),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserGalleryScreen())),
                    child: Text(l10n.text('open_gallery'), style: const TextStyle(color: Color(0xFF7BB960), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              _buildHomeGalleryList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeGalleryList() {
    final l10n = context.l10n;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('gallery').orderBy('uploadedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!.docs;
        if (items.isEmpty) return const SizedBox.shrink();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 18),
          itemBuilder: (context, index) {
            final payload = items[index].data();
            return GalleryMediaCard(
              url: payload['url'] ?? '',
              type: payload['type'] ?? 'image',
              title: payload['productName'] ?? '',
              description: payload['description'] ?? '',
              onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenViewer(url: payload['url'], type: payload['type']))),
            );
          },
        );
      },
    );
  }

  Widget _buildShop() {
    return AppShell(
      backgroundImage: 'https://images.unsplash.com/photo-1595855759920-86582396756a?q=80&w=1974&auto=format&fit=crop',
      overlayOpacity: 0.3,
      child: const RevolveAgroProducts(),
    );
  }

  Widget _buildCart() {
    return AppShell(
      backgroundImage: 'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=2070&auto=format&fit=crop',
      overlayOpacity: 0.6,
      child: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: _buildCartContent())),
    );
  }

  Widget _buildCartContent() {
    final l10n = context.l10n;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return AppEmptyState(icon: Icons.lock, title: l10n.text('login_required'));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('cart').where('userId', isEqualTo: user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return AppEmptyState(icon: Icons.shopping_cart_outlined, title: l10n.text('no_items_added_cart'));

        final items = docs.map((d) => d.data()).toList();
        final total = items.fold<int>(0, (sum, item) => sum + (item['totalPrice'] as int? ?? 0));

        return Column(
          children: [
            AppSectionHeading(title: l10n.text('cart_checkout_title'), color: Colors.white),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => _CartItemCreativeCard(item: items[index]),
              ),
            ),
            _CartFooter(total: total),
          ],
        );
      },
    );
  }
}

class _DashboardCreativeCard extends StatelessWidget {
  final _QuickModule module;
  final VoidCallback onTap;
  const _DashboardCreativeCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AppGlassCard(
          padding: const EdgeInsets.all(16),
          color: Colors.white.withOpacity(0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: module.color.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                    child: Icon(module.icon, color: Colors.white, size: 24),
                  ),
                  const Icon(Icons.park_rounded, color: Color(0x667BB960), size: 30),
                ],
              ),
              const Spacer(),
              Text(l10n.text(module.title.toLowerCase().replaceAll(' ', '_')), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 4),
              Text(module.subtitle, maxLines: 2, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCreativeCard extends StatelessWidget {
  final _InsightCardData insight;
  const _InsightCreativeCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(
        children: [
          Container(height: 44, width: 44, decoration: BoxDecoration(color: const Color(0xFF7BB960).withOpacity(0.3), shape: BoxShape.circle), child: Icon(insight.icon, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                Text(insight.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCreativeCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CartItemCreativeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(item['imageUrl'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.spa, color: Colors.white))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['productName'] ?? 'Product', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Qty: ${item['quantity']}  ·  ₹${item['unitPrice']}', style: TextStyle(color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          Text('₹${item['totalPrice']}', style: const TextStyle(color: Color(0xFF7BB960), fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}

class _CartFooter extends StatelessWidget {
  final int total;
  const _CartFooter({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TOTAL AMOUNT', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
            Text('₹$total', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          ]),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7BB960), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('Checkout Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _QuickModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int destinationIndex;
  const _QuickModule({required this.title, required this.subtitle, required this.icon, required this.color, required this.destinationIndex});
}

class _InsightCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  const _InsightCardData({required this.title, required this.subtitle, required this.icon, required this.tint});
}