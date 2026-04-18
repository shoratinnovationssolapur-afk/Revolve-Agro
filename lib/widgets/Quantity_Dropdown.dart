
import 'package:flutter/material.dart';
import '../screens/buy_now_page.dart';

class BulkOrderSheet extends StatefulWidget {
  final Map<String, dynamic> product;
  final String role;

  const BulkOrderSheet({super.key, required this.product, required this.role});

  @override
  State<BulkOrderSheet> createState() => _BulkOrderSheetState();
}

class _BulkOrderSheetState extends State<BulkOrderSheet> {
  int selectedQty = 50;

  final List<int> quantities = [50, 100, 150, 200, 500, 1000];

  @override
  Widget build(BuildContext context) {
    final variants = widget.product['variants'] ?? [];
    final price = variants.isNotEmpty
        ? variants[0]['mrpPrice'] ?? 0
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      child: Column(
        children: [
          const Text("Select Quantity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 20),

          DropdownButton<int>(
            value: selectedQty,
            items: quantities.map((q) {
              return DropdownMenuItem(
                value: q,
                child: Text("$q units"),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => selectedQty = val!);
            },
          ),

          const SizedBox(height: 20),

          Text("Total: ₹${price * selectedQty}",
              style: const TextStyle(fontSize: 16)),

          const Spacer(),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BuyNowPage(
                    product: widget.product,
                    quantity: selectedQty, // 🔥 PASS QUANTITY
                    role: widget.role,
                  ),
                ),
              );
            },
            child: const Text("Proceed"),
          )
        ],
      ),
    );
  }
}
