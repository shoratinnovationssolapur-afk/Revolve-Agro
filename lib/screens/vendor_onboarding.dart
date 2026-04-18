
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/cloudinary_service.dart';

class VendorOnboarding extends StatefulWidget {
  const VendorOnboarding({super.key});

  @override
  State<VendorOnboarding> createState() => _VendorOnboardingState();
}

class _VendorOnboardingState extends State<VendorOnboarding> {
  final PageController controller = PageController();
  int currentPage = 0;


   final businessType = TextEditingController();
   final state = TextEditingController();
   final pincode = TextEditingController();
  final shop = TextEditingController();
  final gst = TextEditingController();
  final city = TextEditingController();

  File? gstImage;
  File? shopImage;

  Future<void> pick(bool isGST) async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        if (isGST) {
          gstImage = File(img.path);
        } else {
          shopImage = File(img.path);
        }
      });
    }
  }

  Future<void> submit() async {
    final cloud = CloudinaryService();

    String? gstUrl =
        gstImage != null ? await cloud.uploadMedia(gstImage!, "image") : null;

    String? shopUrl =
        shopImage != null ? await cloud.uploadMedia(shopImage!, "image") : null;

   final user = FirebaseAuth.instance.currentUser;

await FirebaseFirestore.instance
    .collection('vendors')
    .doc(user!.uid) // ✅ IMPORTANT
    .set({
  'userId': user.uid,
  'email': user.email, // ✅ useful for admin
  'shopName': shop.text,
  'gst': gst.text,
  'gstImage': gstUrl,
  'shopImage': shopUrl,
  'city': city.text,

  // 🔥 ADD THESE (important)
  'businessType': businessType.text,
  'state': state.text,
  'pincode': pincode.text,

  'status': 'pending',
  'createdAt': FieldValue.serverTimestamp(),
});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Submitted")));
  }

  Widget page(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [Text(title), ...children]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vendor Setup")),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: controller,
              onPageChanged: (i) => setState(() => currentPage = i),
              children: [
               page("Shop Info", [
  TextField(
    controller: shop,
    decoration: const InputDecoration(labelText: "Shop Name"),
  ),
  const SizedBox(height: 10),

  TextField(
    controller: businessType,
    decoration: const InputDecoration(labelText: "Business Type"),
  ),
]),
                page("GST", [
                  TextField(controller: gst),
                  ElevatedButton(
                      onPressed: () => pick(true),
                      child: const Text("Upload GST")),
                ]),
                page("Shop Image", [
                  ElevatedButton(
                      onPressed: () => pick(false),
                      child: const Text("Upload Shop Image")),
                ]),
                page("Location", [
  TextField(
    controller: city,
    decoration: const InputDecoration(labelText: "City"),
  ),
  const SizedBox(height: 10),

  TextField(
    controller: state,
    decoration: const InputDecoration(labelText: "State"),
  ),
  const SizedBox(height: 10),

  TextField(
    controller: pincode,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(labelText: "Pincode"),
  ),
]),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: currentPage == 3
                ? submit
                : () => controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease),
            child: Text(currentPage == 3 ? "Submit" : "Next"),
          )
        ],
      ),
    );
  }
}

