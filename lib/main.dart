import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const RevolveAgroApp());
}

class RevolveAgroApp extends StatelessWidget {
  const RevolveAgroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Revolve Agro',
      theme: ThemeData(
        // Matching your website's agricultural green
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}