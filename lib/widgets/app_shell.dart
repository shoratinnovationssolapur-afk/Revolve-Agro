import 'package:flutter/material.dart';
import 'dart:ui';

class AppShell extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final String? backgroundImage;
  final double? overlayOpacity;

  const AppShell({
    super.key,
    required this.child,
    this.colors,
    this.backgroundImage,
    this.overlayOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final palette = colors ?? const [
      Color(0xFFE7F1D9),
      Color(0xFFF7F3E8),
      Color(0xFFFFFBF4),
    ];

    return Scaffold(
      body: Stack(
        children: [
          if (backgroundImage != null)
            Positioned.fill(
              child: Image.network(
                backgroundImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: palette,
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: palette,
                  ),
                ),
              ),
            ),

          if (backgroundImage != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(overlayOpacity ?? 0.2),
              ),
            ),

          child,
        ],
      ),
    );
  }
}

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin; // Added margin
  final BorderRadiusGeometry borderRadius;
  final Color? color;
  final double blur;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.margin, // Added margin
    this.borderRadius = const BorderRadius.all(Radius.circular(30)),
    this.color,
    this.blur = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin, // Apply margin here
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? Colors.white.withOpacity(0.7),
              borderRadius: borderRadius,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppSectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? color;

  const AppSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: color ?? const Color(0xFF183020),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(
              color: (color ?? Colors.grey.shade700).withOpacity(0.8),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class AppPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isSelected;

  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor = const Color(0xFFF4E5C9),
    this.foregroundColor = const Color(0xFF8A5D1A),
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF183020) : backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected ? [
          BoxShadow(
            color: const Color(0xFF183020).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: isSelected ? Colors.white : foregroundColor),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : foregroundColor,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class AppPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final List<Color>? gradient;
  final IconData? badgeIcon;

  const AppPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.actions = const [],
    this.gradient,
    this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient ?? const [
            Color(0xFF183020),
            Color(0xFF30523B),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0x44183020),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              if (leading != null) leading!,
              if (actions.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (badgeIcon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(badgeIcon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 18),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F6A3E).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: const Color(0xFF2F6A3E)),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF183020),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
