import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/inquiry_service.dart';

class AdminInquiriesPage extends StatefulWidget {
  const AdminInquiriesPage({super.key});

  @override
  State<AdminInquiriesPage> createState() => _AdminInquiriesPageState();
}

class _AdminInquiriesPageState extends State<AdminInquiriesPage> {
  String _statusFilter = 'new';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3DE), Color(0xFFF7F3E8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Customer Inquiries',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Refresh',
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Manage messages sent from the Query section.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatusChip(
                        label: 'New',
                        selected: _statusFilter == 'new',
                        color: const Color(0xFF2F6A3E),
                        onTap: () => setState(() => _statusFilter = 'new'),
                      ),
                      const SizedBox(width: 10),
                      _StatusChip(
                        label: 'Read',
                        selected: _statusFilter == 'read',
                        color: const Color(0xFF305C89),
                        onTap: () => setState(() => _statusFilter = 'read'),
                      ),
                      const SizedBox(width: 10),
                      _StatusChip(
                        label: 'All',
                        selected: _statusFilter == 'all',
                        color: const Color(0xFFD9952E),
                        onTap: () => setState(() => _statusFilter = 'all'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  // Fetch all to avoid composite index requirement
                  stream: InquiryService.stream(status: 'all'),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      if (snapshot.error.toString().contains('permission-denied')) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_person_rounded, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'Access Restricted',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Your account may not have the required Admin permissions. Ensure your role is set to Admin in the users collection.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => setState(() {}),
                                  child: const Text('Retry Connection'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text('Error: ${snapshot.error}'),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF2F6A3E)),
                      );
                    }

                    // Client-side filtering to bypass Index requirement
                    final allDocs = snapshot.data!.docs;
                    final docs = _statusFilter == 'all'
                        ? allDocs
                        : allDocs.where((doc) => doc.data()['status'] == _statusFilter).toList();

                    if (docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No inquiries found', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      itemCount: docs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _CountPill(count: docs.length),
                            ),
                          );
                        }

                        final doc = docs[index - 1];
                        return _InquiryCard(
                          id: doc.id,
                          data: doc.data(),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        '$count Total Messages',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF305C89),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? color : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : const Color(0xFF183020),
            ),
          ),
        ),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;

  const _InquiryCard({
    required this.id,
    required this.data,
  });

  String _s(dynamic value) => (value?.toString() ?? '').trim();

  DateTime? _toDate(dynamic ts) {
    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    return null;
  }

  Future<void> _replyEmail(BuildContext context, String email, String subject) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject.trim().isNotEmpty) 'subject': 'Re: $subject',
      },
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open email app')),
    );
  }

  Future<void> _markRead(BuildContext context) async {
    try {
      await InquiryService.markRead(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as read')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _delete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete inquiry?'),
        content: const Text('This will permanently delete the message.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await InquiryService.delete(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _s(data['name']);
    final email = _s(data['email']);
    final phone = _s(data['phone']);
    final subject = _s(data['subject']);
    final message = _s(data['message']);
    final status = _s(data['status']).toLowerCase();
    final createdAt = _toDate(data['createdAt']);

    final isNew = status != 'read';

    final timestampLabel = createdAt == null
        ? ''
        : '${createdAt.day.toString().padLeft(2, '0')}/'
          '${createdAt.month.toString().padLeft(2, '0')}/'
          '${createdAt.year}  '
          '${createdAt.hour.toString().padLeft(2, '0')}:'
          '${createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE2F0D8),
            child: const Icon(Icons.person_outline_rounded, color: Color(0xFF183020)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.isEmpty ? 'Customer' : name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF183020),
                        ),
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF305C89).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF305C89),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subject.isNotEmpty)
                        Text(
                          'SUBJECT: ${subject.toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      if (subject.isNotEmpty) const SizedBox(height: 8),
                      Text(
                        message.isEmpty ? '-' : message,
                        style: const TextStyle(
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF183020),
                        ),
                      ),
                    ],
                  ),
                ),
                if (timestampLabel.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    timestampLabel,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            children: [
              SizedBox(
                width: 140,
                child: ElevatedButton.icon(
                  onPressed: email.isEmpty ? null : () => _replyEmail(context, email, subject),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF183020),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.reply_rounded, size: 18),
                  label: const Text('Reply via Email'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 140,
                child: OutlinedButton.icon(
                  onPressed: !isNew ? null : () => _markRead(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2F6A3E),
                    side: BorderSide(color: const Color(0xFF2F6A3E).withOpacity(0.35)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: const Color(0xFF2F6A3E).withOpacity(0.06),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Mark Read'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 140,
                child: OutlinedButton.icon(
                  onPressed: () => _delete(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.red.withOpacity(0.06),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
