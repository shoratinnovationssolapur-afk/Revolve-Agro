import 'package:flutter/material.dart';

import '../app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final l10n = context.l10n;

    return PopupMenuButton<Locale>(
      tooltip: l10n.text('language'),
      onSelected: AppLanguage.changeLocale,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: const Locale('en'),
          child: Text(l10n.text('english')),
        ),
        PopupMenuItem(
          value: const Locale('mr'),
          child: Text(l10n.text('marathi')),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 18, color: Color(0xFF2F6A3E)),
            const SizedBox(width: 8),
            Text(
              locale.languageCode == 'mr' ? l10n.text('marathi') : l10n.text('english'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF214B2D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
