
import 'package:flutter/material.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final String? preferredRole;

  const WelcomeScreen({super.key, this.preferredRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF183020), Color(0xFF30523B)],
          ),
        ),
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const AuthScreen()));
            },
            child: const Text("Get Started"),
          ),
        ),
      ),
    );
  }
}