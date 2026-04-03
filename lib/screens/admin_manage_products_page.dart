import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'cloudinary_service.dart';
import 'welcome_screen.dart';

class AdminManageProductsPage extends StatefulWidget {
  const AdminManageProductsPage({super.key});

  @override
  State<AdminManageProductsPage> createState() =>
      _AdminManageProductsPageState();
}

class _AdminManageProductsPageState extends State<AdminManageProductsPage> {
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final TextEditingController _addNameController = TextEditingController();
  final TextEditingController _addDetailsController = TextEditingController();
  final TextEditingController _addDescriptionController =
      TextEditingController();
  final TextEditingController _addPriceController = TextEditingController();
  final TextEditingController _addInventoryController =
      TextEditingController();

  File? _addImageFile;
  String? _addImageUrlPreview;

  bool _isSavingAdd = false;
  bool _isSavingEdit = false;

  @override
  void dispose() {
    _addNameController.dispose();
    _addDetailsController.dispose();
    _addDescriptionController.dispose();
    _addPriceController.dispose();
    _addInventoryController.dispose();
    super.dispose();
  }

  Future<void> _pickAddImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() {
      _addImageFile = File(image.path);
      _addImageUrlPreview = null;
    });
  }

  Future<String?> _uploadImageIfNeeded(File? file) async {
    if (file == null) return null;
    return _cloudinaryService.uploadMedia(file, 'image');
  }

  Future<void> _addProduct() async {
    if (_isSavingAdd) return;

    final name = _addNameController.text.trim();
    final details = _addDetailsController.text.trim();
    final description = _addDescriptionController.text.trim();

    final price = int.tryParse(_addPriceController.text.trim());
    final inventoryQuantity =
        int.tryParse(_addInventoryController.text.trim());

    if (name.isEmpty || details.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill name, details and description.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (price == null || price < 0 || inventoryQuantity == null || inventoryQuantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid price and inventory quantity.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_addImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product image.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSavingAdd = true);
    try {
      final imageUrl = await _uploadImageIfNeeded(_addImageFile);
      if (imageUrl == null) {
        throw Exception('Image upload failed');
      }

      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'details': details,
        'description': description,
        'imageUrl': imageUrl,
        'price': price,
        'inventoryQuantity': inventoryQuantity,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully.')),
      );

      _addNameController.clear();
      _addDetailsController.clear();
      _addDescriptionController.clear();
      _addPriceController.clear();
      _addInventoryController.clear();
      setState(() {
        _addImageFile = null;
        _addImageUrlPreview = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSavingAdd = false);
    }
  }

  Future<void> _showEditDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (_isSavingEdit) return;

    final data = doc.data();
    final String originalImageUrl = (data['imageUrl'] ?? '').toString();

    final TextEditingController nameController =
        TextEditingController(text: (data['name'] ?? '').toString());
    final TextEditingController detailsController =
        TextEditingController(text: (data['details'] ?? '').toString());
    final TextEditingController descriptionController =
        TextEditingController(text: (data['description'] ?? '').toString());

    final priceRaw = data['price'];
    final invRaw = data['inventoryQuantity'];
    final int price = priceRaw is num
        ? priceRaw.toInt()
        : int.tryParse((priceRaw ?? 0).toString()) ?? 0;
    final int inventoryQuantity = invRaw is num
        ? invRaw.toInt()
        : int.tryParse((invRaw ?? 0).toString()) ?? 0;

    final TextEditingController priceController = TextEditingController(
      text: price.toString(),
    );
    final TextEditingController inventoryController = TextEditingController(
      text: inventoryQuantity.toString(),
    );

    File? editImageFile;
    String? editImagePreviewUrl;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickEditImage() async {
              final XFile? image = await _picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 85,
              );
              if (image == null) return;
              setDialogState(() {
                editImageFile = File(image.path);
                editImagePreviewUrl = null;
              });
            }

            Future<void> saveEdit() async {
              if (_isSavingEdit) return;

              final name = nameController.text.trim();
              final details = detailsController.text.trim();
              final description = descriptionController.text.trim();
              final price = int.tryParse(priceController.text.trim());
              final inventoryQuantity =
                  int.tryParse(inventoryController.text.trim());

              if (name.isEmpty || details.isEmpty || description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please fill name, details and description.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (price == null ||
                  price < 0 ||
                  inventoryQuantity == null ||
                  inventoryQuantity < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter valid price and inventory quantity.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() => _isSavingEdit = true);
              try {
                String? imageUrlToSave;
                if (editImageFile != null) {
                  imageUrlToSave =
                      await _uploadImageIfNeeded(editImageFile);
                  if (imageUrlToSave == null) {
                    throw Exception('Image upload failed');
                  }
                }

                final updateData = <String, dynamic>{
                  'name': name,
                  'details': details,
                  'description': description,
                  'price': price,
                  'inventoryQuantity': inventoryQuantity,
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (imageUrlToSave != null) {
                  updateData['imageUrl'] = imageUrlToSave;
                }

                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(doc.id)
                    .update(updateData);

                if (!mounted) return;
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update product: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) setState(() => _isSavingEdit = false);
              }
            }

            return AlertDialog(
              title: const Text('Edit Product'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 86,
                              height: 86,
                              color: Colors.grey[200],
                              child: editImageFile != null
                                  ? Image.file(
                                      editImageFile!,
                                      fit: BoxFit.cover,
                                    )
                                  : (editImagePreviewUrl != null
                                      ? Image.network(
                                          editImagePreviewUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : (originalImageUrl.isNotEmpty
                                          ? Image.network(
                                              originalImageUrl,
                                              fit: BoxFit.cover,
                                            )
                                          : const Icon(Icons.image_not_supported))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: pickEditImage,
                                  icon: const Icon(Icons.image_search_rounded),
                                  label: const Text('Change Image'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Product Name'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: detailsController,
                        decoration: const InputDecoration(
                          labelText: 'Details',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descriptionController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: inventoryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Inventory Quantity',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSavingEdit ? null : saveEdit,
                          child: _isSavingEdit
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    detailsController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    inventoryController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF3DE),
              Color(0xFFF7F3E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF183020), Color(0xFF30523B)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const WelcomeScreen(preferredRole: 'Admin'),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Manage Products',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add New Product',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 86,
                                      height: 86,
                                      color: Colors.grey[200],
                                      child: _addImageFile != null
                                          ? Image.file(
                                              _addImageFile!,
                                              fit: BoxFit.cover,
                                            )
                                          : (_addImageUrlPreview != null
                                              ? Image.network(
                                                  _addImageUrlPreview!,
                                                  fit: BoxFit.cover,
                                                )
                                              : const Icon(Icons.image_not_supported)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _isSavingAdd ? null : _pickAddImage,
                                      icon: const Icon(Icons.add_photo_alternate_rounded),
                                      label: const Text('Select Image'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2F6A3E),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _addNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Product Name',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _addDetailsController,
                                decoration: const InputDecoration(
                                  labelText: 'Details',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _addDescriptionController,
                                minLines: 2,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _addPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Price (Rs.)',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _addInventoryController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Inventory Quantity',
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSavingAdd ? null : _addProduct,
                                  child: _isSavingAdd
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Add Product'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Existing Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('products')
                            .orderBy('updatedAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No products found. Add your first product above.',
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data();
                              final name = (data['name'] ?? '').toString();
                              final imageUrl = (data['imageUrl'] ?? '').toString();
                              final priceRaw = data['price'];
                              final invRaw = data['inventoryQuantity'];
                              final int price = priceRaw is num
                                  ? priceRaw.toInt()
                                  : int.tryParse(priceRaw?.toString() ?? '0') ?? 0;
                              final int inventoryQuantity = invRaw is num
                                  ? invRaw.toInt()
                                  : int.tryParse(invRaw?.toString() ?? '0') ?? 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        width: 84,
                                        height: 84,
                                        color: Colors.grey[200],
                                        child: imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Icon(Icons.broken_image_outlined),
                                              )
                                            : const Icon(Icons.image_not_supported_outlined),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name.isNotEmpty ? name : 'Unnamed Product',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Rs.$price/=',
                                            style: const TextStyle(
                                              color: Color(0xFF2F6A3E),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Stock: $inventoryQuantity',
                                            style: TextStyle(
                                              color: inventoryQuantity <= 0
                                                  ? Colors.red
                                                  : Colors.green.shade700,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: _isSavingEdit
                                                  ? null
                                                  : () => _showEditDialog(
                                                        doc,
                                                      ),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              label: const Text('Edit'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 30),
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
}

