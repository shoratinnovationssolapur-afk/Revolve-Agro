import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'user_dashboard.dart';
import 'vendor_dashboard.dart';
import 'admin/admin_dashboard_page.dart';
import 'admin/super_admin_dashboard_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;

  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();

  String role = 'User'; // used only for signup

  Future<void> handleAuth() async {
    if (email.text.trim().isEmpty || password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email & password")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // ✅ LOGIN
        final cred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text.trim(),
        );

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .get();

        if (!doc.exists) {
          await FirebaseAuth.instance.signOut();
          throw Exception("User data not found");
        }

        final userRole =
            (doc.data()?['role'] ?? 'User').toString().trim().toLowerCase();

        if (!mounted) return;

        // ✅ ROLE BASED NAVIGATION
        switch (userRole) {
          case 'vendor':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const VendorDashboard()),
            );
            break;

          case 'admin':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
            );
            break;

          case 'superadmin':
          case 'super_admin':
          case 'super admin':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const SuperAdminDashboardPage()),
            );
            break;

          default:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserDashboard()),
            );
        }
      } else {
        // ✅ SIGNUP

        if (name.text.trim().isEmpty) {
          throw Exception("Enter name");
        }

        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'name': name.text.trim(),
          'email': email.text.trim(),
          'role': role, // User or Vendor only
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully")),
        );

        setState(() => isLogin = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  Widget field(String label, TextEditingController c,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: c,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E5631), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(blurRadius: 20, color: Colors.black26),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, size: 60, color: Colors.green),
                  const SizedBox(height: 10),

                  Text(
                    isLogin ? "Welcome Back" : "Create Account",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (!isLogin) field("Name", name),

                  field("Email", email),
                  field("Password", password, isPassword: true),

                  if (!isLogin)
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      items: ['User', 'Vendor']
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => setState(() => role = val!),
                      decoration: InputDecoration(
                        labelText: "Select Role",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleAuth,
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : Text(isLogin ? "Login" : "Register"),
                    ),
                  ),

                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin
                          ? "Don't have an account? Register"
                          : "Already have an account? Login",
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
}
