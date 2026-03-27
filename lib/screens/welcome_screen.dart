import 'package:flutter/material.dart';
import 'role_selection_screen.dart';
import 'product_list.dart'; // Ensure this matches the filename for the products scraper

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white,
                child: Icon(Icons.eco, size: 80, color: Colors.green),
              ),
              const SizedBox(height: 30),
              const Text(
                "Grow smarter with\nOur Revolve Agro",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Grow | Better | Crops",
                style: TextStyle(fontSize: 16, color: Colors.teal, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 50),

              // PRIMARY BUTTON: Standard flow to Role Selection
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Next >>", style: TextStyle(fontSize: 18)),
              ),

              const SizedBox(height: 15),

              // NEW SECONDARY BUTTON: Direct access to Products Page (The Asynchronous Task)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RevolveAgroProducts()),
                  );
                },
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text("Browse Products Directly"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}