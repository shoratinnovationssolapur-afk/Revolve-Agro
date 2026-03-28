import 'package:firebase_auth/firebase_auth.dart'; // 1. Add this import
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/product_list.dart'; // 2. Import your product list page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      // 3. Use StreamBuilder to check login status automatically
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the snapshot has data, the user is already logged in
          if (snapshot.hasData) {
            return RevolveAgroProducts(); // Jump to products
          }
          // Otherwise, show the Welcome/Login screen
          return const WelcomeScreen();
        },
      ),
    );
  }
}