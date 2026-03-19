import 'package:flutter/material.dart';

class FertilizerGuideScreen extends StatelessWidget {
  const FertilizerGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fertilizer Guide"), // [cite: 146]
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Placeholder for the Product Image (e.g., Coconut Fertilizer)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.eco, size: 100, color: Colors.green),
            ),
            const SizedBox(height: 30),

            // Input Fields from your design
            _buildInputField("Crop Name", "e.g. Coconut"), // [cite: 154]
            const SizedBox(height: 15),
            _buildInputField("Crop Week", "e.g. Week - 4"), // [cite: 155]
            const SizedBox(height: 15),
            _buildInputField("Area", "e.g. 20 Hec"), // [cite: 157]

            const SizedBox(height: 40),

            // Submit Button [cite: 150, 158]
            ElevatedButton(
              onPressed: () {
                // Logic to show results (Page 18)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Submit"), // [cite: 150]
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}