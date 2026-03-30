import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../widgets/language_selector.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF5DE),
              Color(0xFFF7F3E8),
            ],
          ),
        ),
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
                  height: 160,
                  width: 160,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2F6A3E), Color(0xFF6CAA58)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2F6A3E).withOpacity(0.22),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, size: 90, color: Colors.white),
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
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                  ),
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
