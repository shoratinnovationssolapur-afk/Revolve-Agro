import 'package:flutter/material.dart';
import 'marketplace_screen.dart'; // Ensure this file exists in your lib/screens folder

class AuthScreen extends StatefulWidget {
  final String role; // "Farmer" or "Dealer" [cite: 107, 114]
  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

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
          const Text(
              "Revolve Agro",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 30),

        // TextFields based on your UI design [cite: 39, 182]
        const TextField(decoration: InputDecoration(labelText: "User Name", border: OutlineInputBorder())),
        if (!isLogin) ...[
    const SizedBox(height: 15),
    const TextField(decoration: InputDecoration(labelText: "Phone No", border: OutlineInputBorder())),
    ],
    const SizedBox(height: 15),
    const TextField(
    obscureText: true,
    decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder())
    ),

    const SizedBox(height: 30),
    ElevatedButton(
    onPressed: () {
    // Navigates to the Marketplace after "Login" or "SignUp"
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const MarketplaceScreen()),
    );
    },
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 50),
    ),
    child: Text(isLogin ? "Login →" : "SignUp →"),
    ),

    TextButton(
    onPressed: () => setState(() => isLogin = !isLogin),
    child: Text(isLogin
    ? "Don't have account? Register now"
        : "Already have an account? Login"),
    ),
    ],
    ),
    ),
    );
  }
}