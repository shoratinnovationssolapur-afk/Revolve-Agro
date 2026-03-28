import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'marketplace_screen.dart';
import 'product_list.dart';

class AuthScreen extends StatefulWidget {
  final String role; // This must be here to accept "User" or "Admin"

  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;

  // 1. Controllers to capture user input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // 2. The Main Auth Logic
  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);
    try {
      if (isLogin) {
        // LOGIN LOGIC
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // SIGNUP LOGIC
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // CRITICAL: Wait for the document to be created in the 'users' collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'role': widget.role, // "User" or "Admin"
          'createdAt': FieldValue.serverTimestamp(),
        });

        print("✅ Firestore document created for ${userCredential.user!.uid}");
      }

      // After success (Login OR Signup), move to the next screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RevolveAgroProducts()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Auth Error")));
    } catch (e) {
      // This catches Firestore errors specifically
      print("❌ Firestore Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Database Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.role} ${isLogin ? 'Login' : 'Sign Up'}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.eco, size: 50, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text("Revolve Agro", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 30),

            // 4. Linked TextFields
            TextField(
              controller: _emailController, // Use email as username for Firebase Auth
              decoration: const InputDecoration(labelText: "Email / User Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            if (!isLogin) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone No", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
            ],
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),

            isLoading
                ? const CircularProgressIndicator(color: Colors.green)
                : ElevatedButton(
              onPressed: _handleAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(isLogin ? "Login →" : "SignUp →"),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? "Don't have account? Register now" : "Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}