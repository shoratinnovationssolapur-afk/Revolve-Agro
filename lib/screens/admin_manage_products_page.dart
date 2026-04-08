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

  // Standard Inputs (Kept exactly as they were)
  final TextEditingController _addNameController = TextEditingController();
  final TextEditingController _addContentController = TextEditingController();
  final TextEditingController _addDescriptionController = TextEditingController();

  // 🔥 Multi-Variant Controllers (Size, DRP, MRP)
  final List<Map<String, TextEditingController>> _variantControllers = [];

  File? _addImageFile;
  bool _isSavingAdd = false;
  bool _isSavingEdit = false; //

  @override
  void initState() {
    super.initState();
    _addVariantRow(); // Start with one variant row by default
  }

  void _addVariantRow() {
    setState(() {
      _variantControllers.add({
        'size': TextEditingController(),
        'drp': TextEditingController(),
        'mrp': TextEditingController(),
      });
    });
  }

  void _removeVariantRow(int index) {
    if (_variantControllers.length > 1) {
      setState(() {
        for (var c in _variantControllers[index].values) {
          c.dispose();
        }
        _variantControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _addNameController.dispose();
    _addContentController.dispose();
    _addDescriptionController.dispose();
    for (var v in _variantControllers) {
      for (var c in v.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _pickAddImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() => _addImageFile = File(image.path));
  }

  Future<String?> _uploadImageIfNeeded(File? file) async {
    if (file == null) return null;
    return _cloudinaryService.uploadMedia(file, 'image');
  }

  Future<void> _addProduct() async {
    if (_isSavingAdd) return;

    final name = _addNameController.text.trim();
    final content = _addContentController.text.trim();
    final description = _addDescriptionController.text.trim();

    // Mapping variants to data
    List<Map<String, dynamic>> variants = _variantControllers.map((v) {
      return {
        'packingSize': v['size']!.text.trim(),
        'drpPrice': int.tryParse(v['drp']!.text.trim()) ?? 0,
        'mrpPrice': int.tryParse(v['mrp']!.text.trim()) ?? 0,
      };
    }).toList();

    if (name.isEmpty || content.isEmpty || _addImageFile == null || variants.any((v) => v['packingSize'].isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and add at least one packing size.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSavingAdd = true);
    try {
      final imageUrl = await _uploadImageIfNeeded(_addImageFile);

      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'details': content,
        'description': description,
        'imageUrl': imageUrl,
        'variants': variants, // 🔥 List of sizes/prices
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear all fields
      _addNameController.clear();
      _addContentController.clear();
      _addDescriptionController.clear();
      setState(() {
        _addImageFile = null;
        for (var v in _variantControllers) {
          for (var c in v.values) {
            c.clear();
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product & Variants added successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSavingAdd = false);
    }
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
            IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
            const SizedBox(width: 10),
            const Text('Inventory Manager', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
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
            GestureDetector(
              onTap: _pickAddImage,
              child: Container(
                height: 120, width: 120,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[300]!)),
                child: _addImageFile != null ? Image.file(_addImageFile!, fit: BoxFit.cover) : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40), Text('Add Image')]),
              ),
            ),
            TextField(controller: _addNameController, decoration: const InputDecoration(labelText: 'Product Name (e.g. HUSTLER ZINC)')),
            TextField(controller: _addContentController, decoration: const InputDecoration(labelText: 'Content (e.g. Zinc Chelated 12%)')),
            TextField(controller: _addDescriptionController, maxLines: 2, decoration: const InputDecoration(labelText: 'Full Description')),

            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text("Packing Sizes & Pricing", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const Divider(),

            // 🔥 List of Variant Inputs
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _variantControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: TextField(controller: _variantControllers[index]['size'], decoration: const InputDecoration(hintText: 'Size (500ml)'))),
                      const SizedBox(width: 5),
                      Expanded(flex: 1, child: TextField(controller: _variantControllers[index]['drp'], keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'DRP'))),
                      const SizedBox(width: 5),
                      Expanded(flex: 1, child: TextField(controller: _variantControllers[index]['mrp'], keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'MRP'))),
                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _removeVariantRow(index)),
                    ],
                  ),
                );
              },
            ),
            TextButton.icon(onPressed: _addVariantRow, icon: const Icon(Icons.add_circle_outline), label: const Text("Add Another Packing Size")),

            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _isSavingAdd ? null : _addProduct,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F6A3E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: _isSavingAdd ? const CircularProgressIndicator(color: Colors.white) : const Text('ADD TO INVENTORY'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();

    final nameController = TextEditingController(text: data['name']?.toString());
    final contentController = TextEditingController(text: data['details']?.toString());
    final descController = TextEditingController(text: data['description']?.toString()); // 🔥 Description Controller

    List<Map<String, TextEditingController>> editVariants = [];
    List rawVariants = data['variants'] ?? [];

    if (rawVariants.isEmpty && data['packingSize'] != null) {
      editVariants.add({
        'size': TextEditingController(text: data['packingSize'].toString()),
        'drp': TextEditingController(text: data['price'].toString()),
        'mrp': TextEditingController(text: data['mrpPrice']?.toString() ?? ''),
      });
    } else {
      for (var v in rawVariants) {
        editVariants.add({
          'size': TextEditingController(text: v['packingSize'].toString()),
          'drp': TextEditingController(text: v['drpPrice'].toString()),
          'mrp': TextEditingController(text: v['mrpPrice'].toString()),
        });
      }
    }

    File? editImageFile;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Product Details'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (img != null) {
                          setDialogState(() => editImageFile = File(img.path));
                        }
                      },
                      child: Container(
                        height: 100, width: 100,
                        decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey[300]!)
                        ),
                        child: editImageFile != null
                            ? Image.file(editImageFile!, fit: BoxFit.cover)
                            : (data['imageUrl'] != null
                            ? Image.network(data['imageUrl'], fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo, size: 40)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
                    TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Content')),

                    // 🔥 NEW: Description Field in Edit Dialog
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),

                    const SizedBox(height: 15),
                    const Align(alignment: Alignment.centerLeft, child: Text("Packing Sizes:", style: TextStyle(fontWeight: FontWeight.bold))),
                    const Divider(),

                    ...editVariants.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var v = entry.value;
                      return Row(
                        children: [
                          Expanded(child: TextField(controller: v['size'], decoration: const InputDecoration(hintText: 'Size'))),
                          const SizedBox(width: 4),
                          Expanded(child: TextField(controller: v['drp'], decoration: const InputDecoration(hintText: 'DRP'))),
                          const SizedBox(width: 4),
                          Expanded(child: TextField(controller: v['mrp'], decoration: const InputDecoration(hintText: 'MRP'))),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                            onPressed: () => setDialogState(() => editVariants.removeAt(idx)),
                          ),
                        ],
                      );
                    }),

                    TextButton.icon(
                      onPressed: () => setDialogState(() => editVariants.add({
                        'size': TextEditingController(),
                        'drp': TextEditingController(),
                        'mrp': TextEditingController(),
                      })),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Size"),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: _isSavingEdit ? null : () async {
                  setDialogState(() => _isSavingEdit = true);
                  try {
                    String? newImageUrl;
                    if (editImageFile != null) {
                      newImageUrl = await _cloudinaryService.uploadMedia(editImageFile!, 'image');
                    }

                    List<Map<String, dynamic>> updatedVariants = editVariants.map((v) => {
                      'packingSize': v['size']!.text.trim(),
                      'drpPrice': int.tryParse(v['drp']!.text.trim()) ?? 0,
                      'mrpPrice': int.tryParse(v['mrp']!.text.trim()) ?? 0,
                    }).toList();

                    Map<String, dynamic> updateData = {
                      'name': nameController.text.trim(),
                      'details': contentController.text.trim(),
                      'description': descController.text.trim(), // 🔥 UPDATING DESCRIPTION
                      'variants': updatedVariants,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (newImageUrl != null) updateData['imageUrl'] = newImageUrl;

                    await FirebaseFirestore.instance.collection('products').doc(doc.id).update(updateData);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e")));
                  } finally {
                    setDialogState(() => _isSavingEdit = false);
                  }
                },
                child: _isSavingEdit
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Update All'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').orderBy('updatedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();

            // 🔥 Fix: Handle both old data (single packing) and new data (variants list)
            List variants = data['variants'] ?? [];

            // If variants is empty but old data exists, show the old data
            if (variants.isEmpty && data['packingSize'] != null) {
              variants = [{
                'packingSize': data['packingSize'],
                'drpPrice': data['price'] ?? 0,
                'mrpPrice': data['mrpPrice'] ?? 0, // Fallback if MRP wasn't there
              }];
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ExpansionTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['imageUrl'] ?? '',
                    width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.image),
                  ),
                ),
                title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${variants.length} Sizes Available"),

                // 🔥 Adding Edit and Delete Actions
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditDialog(docs[index]), // Re-uses your existing edit logic
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(docs[index].id),
                    ),
                    const Icon(Icons.expand_more),
                  ],
                ),

                children: variants.map((v) => ListTile(
                  dense: true,
                  title: Text("Packing: ${v['packingSize']}"),
                  subtitle: Text("DRP: ₹${v['drpPrice']} | MRP: ₹${v['mrpPrice']}"),
                  tileColor: Colors.grey[50],
                )).toList(),
              ),
            );
          },
        );
      },
    );
  }

// 🔥 Simple Delete Confirmation
  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product?"),
        content: const Text("This will permanently remove this product from inventory."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('products').doc(docId).delete();
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}