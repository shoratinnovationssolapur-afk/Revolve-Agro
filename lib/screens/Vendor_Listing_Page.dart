import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VendorListingPage extends StatefulWidget {
  const VendorListingPage({super.key});

  @override
  State<VendorListingPage> createState() => _VendorListingPageState();
}

class _VendorListingPageState extends State<VendorListingPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for the fields from your screenshots
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _talukaController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();

  String? _selectedBusinessType;
  String? _selectedState;

  // Function to save the vendor data to Firebase
  Future<void> _registerVendor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('vendors').add({
        'shopName': _shopNameController.text.trim(),
        'email': _emailController.text.trim(),
        'businessType': _selectedBusinessType,
        'village': _villageController.text.trim(),
        'taluka': _talukaController.text.trim(),
        'pinCode': _pinCodeController.text.trim(),
        'gstNumber': _gstController.text.trim(),
        'state': _selectedState,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // For admin approval
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Submitted Successfully!")),
        );
        Navigator.pop(context); // Go back after success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3E8),
      appBar: AppBar(
        title: const Text("Vendor Registration"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF183020),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F6A3E)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Shop Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              _buildField(_shopNameController, "Shop Name *", Icons.storefront),
              _buildField(_emailController, "Email ID *", Icons.email, type: TextInputType.emailAddress),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Business Type *", prefixIcon: Icon(Icons.business)),
                items: ["Retailer", "Distributor", "Wholesaler"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => _selectedBusinessType = val,
                validator: (val) => val == null ? "Please select type" : null,
              ),

              const SizedBox(height: 25),
              const Text("Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              _buildField(_villageController, "Village *", Icons.location_city),
              _buildField(_talukaController, "Taluka *", Icons.map),
              _buildField(_pinCodeController, "Pin Code *", Icons.pin_drop, type: TextInputType.number),

              const SizedBox(height: 25),
              const Text("Legal Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              _buildField(_gstController, "GST Number *", Icons.assignment_turned_in),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _registerVendor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6A3E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("CONTINUE →", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (val) => val!.isEmpty ? "Required" : null,
      ),
    );
  }
}