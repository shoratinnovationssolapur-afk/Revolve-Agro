import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import '../widgets/language_selector.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: AppShell(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Spacer(),
                    const LanguageSelector(),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF7CB961),
                        Color(0xFF2F6A3E),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2F6A3E).withOpacity(0.22),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, size: 96, color: Colors.white),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.text('payment_successful'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183020),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.text('payment_success_subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 24),
                AppGlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: Color(0xFFD9952E)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.text('next_step_delivery'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(l10n.text('back_to_marketplace')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
