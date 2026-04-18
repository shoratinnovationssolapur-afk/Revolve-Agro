import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import '../app_localizations.dart';

import '../widgets/app_shell.dart';

class UserInquiriesPage extends StatelessWidget {
  const UserInquiriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = context.l10n;

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('My Support History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: user == null
            ? Center(child: Text(l10n.text('login_required'), style: const TextStyle(color: Colors.white)))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('inquiries')
                    .where('userId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  if (snapshot.hasError) {
                    // Showing actual error for debugging
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Database Error: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          const Text('No queries sent yet', style: TextStyle(color: Colors.white, fontSize: 18)),
                        ],
                      ),
                    );
                  }

                  final sortedDocs = docs.toList()
                    ..sort((a, b) {
                      final da = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                      final db = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                      return db.compareTo(da);
                    });

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    itemCount: sortedDocs.length,
                    itemBuilder: (context, index) {
                      final data = sortedDocs[index].data();
                      final status = data['status'] ?? 'new';
                      final subject = data['subject'] ?? 'No Subject';
                      final message = data['message'] ?? '';
                      final date = (data['createdAt'] as Timestamp?)?.toDate();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: AppGlassCard(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'read' ? const Color(0xFF7BB960).withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(color: status == 'read' ? const Color(0xFF7BB960) : Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                                if (date != null)
                                  Text('${date.day}/${date.month}/${date.year}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(subject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 6),
                            Text(message, style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.4)),
                          ],
                        ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}