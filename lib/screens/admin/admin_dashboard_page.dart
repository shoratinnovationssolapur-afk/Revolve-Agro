import 'package:flutter/material.dart';
import 'admin_manage_products_page.dart';
import 'admin_orders_page.dart';
import '../widgets/language_selector.dart';
import '../utils/helpline.dart';
import 'welcome_screen.dart';
import 'admin_gallery_screen.dart'; // ✅ Added
import 'profile_page.dart'; // ✅ Added

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_DashboardItem> _items = const [
    _DashboardItem(
      label: 'View Orders',
      subtitle: 'Track and approve orders',
      icon: Icons.inbox_rounded,
      color: Color(0xFF2F6A3E),
      destination: AdminOrdersPage(),
    ),
    _DashboardItem(
      label: 'Manage Products',
      subtitle: 'Add, edit, and update stock',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFFD9952E),
      destination: AdminManageProductsPage(),
    ),
    _DashboardItem(
      label: 'Manage Gallery',
      subtitle: 'Update images and posters',
      icon: Icons.photo_library_rounded,
      color: Color(0xFF1E5631),
      destination: AdminGalleryScreen(),
    ),
    _DashboardItem(
      label: 'Profile Settings',
      subtitle: 'Manage admin preferences',
      icon: Icons.admin_panel_settings_rounded,
      color: Color(0xFF333333),
      destination: ProfilePage(role: 'Admin'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF3DE),
              Color(0xFFF7F3E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔥 HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF183020), Color(0xFF30523B)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const WelcomeScreen(preferredRole: 'Admin'),
                            ),
                                (route) => false,
                          );
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Helpline (WhatsApp)',
                        onPressed: () => openHelplineWhatsApp(context),
                        icon: const Icon(Icons.support_agent_rounded),
                      ),
                      const SizedBox(width: 8),
                      const LanguageSelector(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 🔥 DASHBOARD CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 14),
                          child: _QuickStatsStrip(
                            accent: Color(0xFF2F6A3E),
                            items: [
                              _StatChip(
                                label: 'Orders',
                                icon: Icons.receipt_long_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminOrdersPage(),
                                    ),
                                  );
                                },
                              ),
                              _StatChip(
                                label: 'Products',
                                icon: Icons.inventory_2_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AdminManageProductsPage(),
                                    ),
                                  );
                                },
                              ),
                              _StatChip(
                                label: 'Gallery',
                                icon: Icons.photo_library_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AdminGalleryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final crossAxisCount = width >= 900
                              ? 4
                              : width >= 640
                                  ? 3
                                  : width < 310
                                      ? 1
                                      : 2;
                          final childAspectRatio = crossAxisCount == 1
                              ? 1.8
                              : crossAxisCount >= 3
                                  ? 1.35
                                  : width < 360
                                      ? 0.95
                                      : 1.18;

                          return SliverPadding(
                            padding: const EdgeInsets.only(bottom: 18),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = _items[index];
                                  final t = index / (_items.length + 2);
                                  final animation = CurvedAnimation(
                                    parent: _controller,
                                    curve: Interval(
                                      (0.12 + t).clamp(0.0, 1.0),
                                      (0.85 + t).clamp(0.0, 1.0),
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );

                                  return _DashboardTile(
                                    item: item,
                                    animation: animation,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              item.destination,
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: _items.length,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: childAspectRatio,
                              ),
                            ),
                          );
                        },
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: Text(
                            'Workspace for Revolve Agro management.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ✅ HELPER METHOD FOR MENU BUTTONS
}

class _DashboardItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget destination;

  const _DashboardItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.destination,
  });
}

class _DashboardTile extends StatelessWidget {
  final _DashboardItem item;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.item,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Color.lerp(item.color, Colors.white, 0.90)!;
    final border = Color.lerp(item.color, Colors.white, 0.72)!;
    final opacity = Tween<double>(begin: 0.01, end: 1).animate(animation);

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(item.icon, color: item.color),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.25,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatChip({required this.label, required this.icon, this.onTap});
}

class _QuickStatsStrip extends StatelessWidget {
  final Color accent;
  final List<_StatChip> items;

  const _QuickStatsStrip({
    required this.accent,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.55)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: items
            .map(
              (item) => _QuickChip(
                icon: item.icon,
                label: item.label,
                color: accent,
                onTap: item.onTap,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: borderRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
