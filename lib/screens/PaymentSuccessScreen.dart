import 'package:flutter/material.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header: Back to Marketplace
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 10),
                      Text("Back to Marketplace", style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            // 2. Success Icon
            const CircleAvatar(
              radius: 100,
              backgroundColor: Color(0xFF2DB900), // Bright green
              child: Icon(Icons.check, size: 120, color: Colors.white),
            ),

            const SizedBox(height: 50),

            // 3. Success Message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              color: Colors.black,
              child: const Text(
                "Payment Success !",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            const Spacer(),

            // 4. Bottom Navigation (Static for now)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(icon: const Icon(Icons.home_outlined, size: 35), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.menu, size: 35), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.person_outline, size: 35), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.logout_rounded, size: 35), onPressed: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}