import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String kHelplineWhatsAppPhoneDigits = '917397820357';

Uri helplineWhatsAppUri({
  String? message,
}) {
  final base = Uri.parse('https://wa.me/$kHelplineWhatsAppPhoneDigits');
  final trimmed = message?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return base;
  }
  return base.replace(queryParameters: {'text': trimmed});
}

Future<void> openHelplineWhatsApp(
  BuildContext context, {
  String? message,
}) async {
  final uri = helplineWhatsAppUri(message: message);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (ok) return;

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Could not open WhatsApp. Please message 7397820357.'),
    ),
  );
}

