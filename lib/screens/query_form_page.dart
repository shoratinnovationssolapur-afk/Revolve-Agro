import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import '../app_localizations.dart';
import '../services/inquiry_service.dart';
import '../widgets/app_shell.dart';

class QueryFormPage extends StatefulWidget {
  const QueryFormPage({super.key});

  @override
  State<QueryFormPage> createState() => _QueryFormPageState();
}

class _QueryFormPageState extends State<QueryFormPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  late final AnimationController _animController;

  bool _submitting = false;
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _prefill();
    _animController.forward();
  }

  Future<void> _prefill() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _name.text = user.displayName ?? '';
      _email.text = user.email ?? '';
    });
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists) {
        setState(() {
          _name.text = doc.data()?['name'] ?? _name.text;
          _email.text = doc.data()?['email'] ?? _email.text;
          _phone = doc.data()?['phone'] ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _subject.dispose(); _message.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await InquiryService.submit(name: _name.text, email: _email.text, phone: _phone, subject: _subject.text, message: _message.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.text('query_sent'))));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppShell(
      backgroundImage: 'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?q=80&w=2070&auto=format&fit=crop',
      overlayOpacity: 0.5,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: FadeTransition(
            opacity: _animController,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1))),
                  const SizedBox(height: 30),
                  const Text('Send Us a Message', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('We are here to help you grow', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                  const SizedBox(height: 40),
                  AppGlassCard(
                    color: Colors.white.withOpacity(0.15),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField(_name, 'Your Name', Icons.person_outline),
                          const SizedBox(height: 20),
                          _buildField(_email, 'Email Address', Icons.email_outlined, TextInputType.emailAddress),
                          const SizedBox(height: 20),
                          _buildField(_subject, 'Subject', Icons.topic_outlined),
                          const SizedBox(height: 20),
                          _buildField(_message, 'Message', Icons.message_outlined, TextInputType.multiline, true),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded),
                              label: Text(_submitting ? 'Sending...' : 'Send Message', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7BB960), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, [TextInputType type = TextInputType.text, bool multi = false]) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: multi ? 5 : 1,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
        filled: true, fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7BB960))),
      ),
    );
  }
}
