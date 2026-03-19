import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart'; // This connects your files

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}