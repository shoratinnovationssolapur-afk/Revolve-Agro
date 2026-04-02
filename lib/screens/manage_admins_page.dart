import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageAdminsPage extends StatelessWidget {
  const ManageAdminsPage({super.key});

  Future<void> _setRole({
    required BuildContext context,
    required String userId,
    required String nextRole,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {
          'role': nextRole,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated to $nextRole')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteUserRecord({
    required BuildContext context,
    required String userId,
    required String name,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text('Delete $name from members list?'),
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
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted from database.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

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
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A1638), Color(0xFF4B2A63)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Manage Admins',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('No members found.'));
                    }
                    QueryDocumentSnapshot<Map<String, dynamic>>? currentUserDoc;
                    if (currentUser != null) {
                      for (final u in docs) {
                        if (u.id == currentUser.uid) {
                          currentUserDoc = u;
                          break;
                        }
                      }
                    }
                    final myRole = currentUserDoc?.data()['role']?.toString() ?? 'User';
                    final isCurrentUserSuperAdmin = myRole == 'SuperAdmin';
                    final isCurrentUserAdmin = myRole == 'Admin';

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();

                        final uid = doc.id;
                        final name = (data['name'] ?? 'Unknown').toString();
                        final email = (data['email'] ?? '').toString();
                        final phone = (data['phone'] ?? '').toString();
                        final role = (data['role'] ?? 'User').toString();

                        final isSelf = currentUser?.uid == uid;
                        final isSuperAdmin = role == 'SuperAdmin';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: role == 'Admin'
                                          ? const Color(0xFFF2D89C)
                                          : (role == 'SuperAdmin'
                                              ? const Color(0xFFE3D2F2)
                                              : const Color(0xFFEAF1E1)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      role,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (email.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(email, style: TextStyle(color: Colors.grey.shade700)),
                              ],
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(phone, style: TextStyle(color: Colors.grey.shade700)),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: (!isCurrentUserSuperAdmin ||
                                              isSelf ||
                                              isSuperAdmin ||
                                              role == 'Admin')
                                          ? null
                                          : () => _setRole(
                                                context: context,
                                                userId: uid,
                                                nextRole: 'Admin',
                                              ),
                                      icon: const Icon(Icons.admin_panel_settings_outlined),
                                      label: const Text('Make Admin'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: (!isCurrentUserSuperAdmin ||
                                              isSelf ||
                                              isSuperAdmin ||
                                              role == 'User')
                                          ? null
                                          : () => _setRole(
                                                context: context,
                                                userId: uid,
                                                nextRole: 'User',
                                              ),
                                      icon: const Icon(Icons.person_outline_rounded),
                                      label: const Text('Make User'),
                                    ),
                                  ),
                                ],
                              ),
                              if (isCurrentUserAdmin) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: (isSelf || isSuperAdmin || role != 'User')
                                        ? null
                                        : () => _deleteUserRecord(
                                              context: context,
                                              userId: uid,
                                              name: name,
                                            ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    label: const Text('Delete User'),
                                  ),
                                ),
                              ],
                              if (isSelf) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'You cannot change your own role.',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (isSuperAdmin) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Super Admin role is protected.',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
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

