import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';
import 'welcome_screen.dart';

class AdminManageProductsPage extends StatefulWidget {
  const AdminManageProductsPage({super.key});

  @override
  State<AdminManageProductsPage> createState() => _AdminManageProductsPageState();
}

class _AdminManageProductsPageState extends State<AdminManageProductsPage> {
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final TextEditingController _addNameController = TextEditingController();
  final TextEditingController _addContentController = TextEditingController(); // Maps to "CONTENT" in PDF
  final TextEditingController _addDescriptionController = TextEditingController();
  final TextEditingController _addPriceController = TextEditingController();
  final TextEditingController _addPackingController = TextEditingController(); // New field for PDF "PACKING SIZE"

  File? _addImageFile;
  bool _isSavingAdd = false;
  bool _isSavingEdit = false;

  @override
  void dispose() {
    _addNameController.dispose();
    _addContentController.dispose();
    _addDescriptionController.dispose();
    _addPriceController.dispose();
    _addPackingController.dispose();
    super.dispose();
  }

  // --- Image Picking Logic ---
  Future<void> _pickAddImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() => _addImageFile = File(image.path));
  }

  Future<String?> _uploadImageIfNeeded(File? file) async {
    if (file == null) return null;
    return _cloudinaryService.uploadMedia(file, 'image');
  }

  // --- Add Product (PDF Styled) ---
  Future<void> _addProduct() async {
    if (_isSavingAdd) return;

    final name = _addNameController.text.trim();
    final content = _addContentController.text.trim();
    final description = _addDescriptionController.text.trim();
    final packing = _addPackingController.text.trim();
    final price = int.tryParse(_addPriceController.text.trim());

    if (name.isEmpty || content.isEmpty || _addImageFile == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill Name, Content, Price and select an Image.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSavingAdd = true);
    try {
      final imageUrl = await _uploadImageIfNeeded(_addImageFile);

      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'details': content, // Storing "Content" from PDF here
        'description': description,
        'packingSize': packing,
        'imageUrl': imageUrl,
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _addNameController.clear();
      _addContentController.clear();
      _addDescriptionController.clear();
      _addPackingController.clear();
      _addPriceController.clear();
      setState(() => _addImageFile = null);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSavingAdd = false);
    }
  }

  // --- Edit Dialog (Fixed Assertion Error) ---
  Future<void> _showEditDialog(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();

    final nameController = TextEditingController(text: data['name']?.toString());
    final contentController = TextEditingController(text: data['details']?.toString());
    final descController = TextEditingController(text: data['description']?.toString());
    final priceController = TextEditingController(text: data['price']?.toString());
    final packingController = TextEditingController(text: data['packingSize']?.toString());

    File? editImageFile;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Product Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
                      if (img != null) setDialogState(() => editImageFile = File(img.path));
                    },
                    child: Container(
                      height: 100, width: 100,
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                      child: editImageFile != null
                          ? Image.file(editImageFile!, fit: BoxFit.cover)
                          : (data['imageUrl'] != null ? Image.network(data['imageUrl'], fit: BoxFit.cover) : const Icon(Icons.add_a_photo)),
                    ),
                  ),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name (e.g. HUSTLER ZINC)')),
                  TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Content (e.g. Zinc Chelated 12%)')),
                  TextField(controller: packingController, decoration: const InputDecoration(labelText: 'Packing Size (e.g. 500gm)')),
                  TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (DRP)')),
                  TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: _isSavingEdit ? null : () async {
                  setDialogState(() => _isSavingEdit = true);
                  try {
                    String? newUrl;
                    if (editImageFile != null) newUrl = await _uploadImageIfNeeded(editImageFile);

                    await FirebaseFirestore.instance.collection('products').doc(doc.id).update({
                      'name': nameController.text.trim(),
                      'details': contentController.text.trim(),
                      'description': descController.text.trim(),
                      'packingSize': packingController.text.trim(),
                      'price': int.tryParse(priceController.text.trim()) ?? 0,
                      'imageUrl': ?newUrl,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) Navigator.pop(context);
                  } finally {
                    setDialogState(() => _isSavingEdit = false);
                  }
                },
                child: _isSavingEdit ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );

    // Dispose controllers ONLY after the dialog is completely finished
    nameController.dispose();
    contentController.dispose();
    descController.dispose();
    priceController.dispose();
    packingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFEAF3DE), Color(0xFFF7F3E8)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      _buildAddCard(),
                      const SizedBox(height: 20),
                      _buildProductList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF183020), Color(0xFF30523B)]), borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [
            IconButton.filledTonal(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const WelcomeScreen(preferredRole: 'Admin'))), icon: const Icon(Icons.arrow_back_rounded)),
            const SizedBox(width: 10),
            const Text('Product Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCard() {
    return Card(
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Add New Product (from Price List)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _pickAddImage,
              child: Container(
                height: 120, width: 120,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[300]!)),
                child: _addImageFile != null ? Image.file(_addImageFile!, fit: BoxFit.cover) : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40), Text('Select Image')]),
              ),
            ),
            TextField(controller: _addNameController, decoration: const InputDecoration(labelText: 'Product Name (e.g. HUSTLER COMBI)')),
            TextField(controller: _addContentController, decoration: const InputDecoration(labelText: 'Content/HSN (e.g. Mix Micronutrient)')),
            TextField(controller: _addPackingController, decoration: const InputDecoration(labelText: 'Packing Size (e.g. 250gm / 500ml)')),
            TextField(controller: _addPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'DRP Price (Rs.)')),
            TextField(controller: _addDescriptionController, maxLines: 2, decoration: const InputDecoration(labelText: 'Short Description')),
            const SizedBox(height: 15),
            ElevatedButton(onPressed: _isSavingAdd ? null : _addProduct, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F6A3E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)), child: _isSavingAdd ? const CircularProgressIndicator(color: Colors.white) : const Text('Add to Inventory')),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').orderBy('updatedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Image.network(data['imageUrl'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)),
                title: Text(data['name'] ?? ''),
                subtitle: Text('DRP: Rs.${data['price']} | ${data['packingSize'] ?? ''}'),
                trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditDialog(docs[index])),
              ),
            );
          },
        );
      },
    );
  }
}