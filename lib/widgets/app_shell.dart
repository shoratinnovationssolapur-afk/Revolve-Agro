import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const AppShell({
    super.key,
    required this.child,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final palette =
        colors ??
        const [
          Color(0xFFE7F1D9),
          Color(0xFFF7F3E8),
          Color(0xFFFFFBF4),
        ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette,
        ),
      ),
      child: child,
    );
  }
}

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.borderRadius = const BorderRadius.all(Radius.circular(30)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.45),
        ),
      ),
      child: child,
    );
  }
}

class AppSectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AppSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF183020),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.grey.shade700,
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

  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor = const Color(0xFFF4E5C9),
    this.foregroundColor = const Color(0xFF8A5D1A),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foregroundColor),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              gradient ??
              const [
                Color(0xFF183020),
                Color(0xFF30523B),
              ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33183020),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              if (leading != null) leading!,
              if (actions.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: actions,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          if (badgeIcon != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(badgeIcon, color: Colors.white),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 30,
              height: 1.05,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.84),
              height: 1.45,
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
              Icon(icon, size: 56, color: const Color(0xFF2F6A3E)),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF183020),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.45,
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
