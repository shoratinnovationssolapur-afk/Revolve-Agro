import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import '../widgets/language_selector.dart';
import 'PaymentSuccessScreen.dart';

class PaymentPage extends StatefulWidget { // 1. Changed to StatefulWidget to handle UI updates after deletion
  final List<Map<String, dynamic>> cartItems;
  final int totalAmount;

  const PaymentPage({
    super.key,
    required this.cartItems,
    required this.totalAmount
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late List<Map<String, dynamic>> currentItems;
  late int currentTotal;
  String deliveryType = 'manual';
  String fullAddress = '';
  String landmark = '';
  String city = '';
  String pincode = '';
  bool isSavingOrder = false;
  bool isFetchingLocation = false;

  Future<void> _showPopup({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    currentItems = List.from(widget.cartItems);
    currentTotal = widget.totalAmount;
    _loadSavedAddress();
  }

  void _showEmptyCartMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.text('no_items_added_cart'))),
    );
  }

  Future<void> _loadSavedAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      if (data == null) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showAddressSheet();
            }
          });
        }
        return;
      }
      if (!mounted) return;

      setState(() {
        deliveryType = data['deliveryType'] ?? 'manual';
        fullAddress = data['fullAddress'] ?? '';
        landmark = data['landmark'] ?? '';
        city = data['city'] ?? '';
        pincode = data['pincode'] ?? '';
      });

      if (_deliverySummary.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showAddressSheet();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading address: $e');
    }
  }

  String get _deliverySummary {
    final parts = [
      fullAddress.trim(),
      landmark.trim(),
      city.trim(),
      pincode.trim(),
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(', ');
  }

  Future<void> _showAddressSheet() async {
    final l10n = context.l10n;
    final addressController = TextEditingController(text: fullAddress);
    final landmarkController = TextEditingController(text: landmark);
    final cityController = TextEditingController(text: city);
    final pincodeController = TextEditingController(text: pincode);
    String selectedType = deliveryType;
    bool isFetchingInSheet = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> fetchCurrentLocation() async {
              setModalState(() => isFetchingInSheet = true);

              final locationData = await _fetchCurrentLocationData();
              if (!mounted || !context.mounted) {
                return;
              }

              if (locationData == null) {
                setModalState(() => isFetchingInSheet = false);
                return;
              }

              addressController.text = locationData['fullAddress'] ?? '';
              landmarkController.text = locationData['landmark'] ?? '';
              cityController.text = locationData['city'] ?? '';
              pincodeController.text = locationData['pincode'] ?? '';

              setModalState(() {
                selectedType = 'current_location';
                isFetchingInSheet = false;
              });

              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(content: Text(l10n.text('current_location_fetched'))),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: SizedBox(
                        width: 45,
                        child: Divider(thickness: 4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.text('choose_delivery_location'),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.text('delivery_location_subtitle'),
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.text('current_location')),
                          selected: selectedType == 'current_location',
                          onSelected: (_) {
                            setModalState(() => selectedType = 'current_location');
                          },
                        ),
                        ChoiceChip(
                          label: Text(l10n.text('manual_address')),
                          selected: selectedType == 'manual',
                          onSelected: (_) {
                            setModalState(() => selectedType = 'manual');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isFetchingInSheet ? null : fetchCurrentLocation,
                        icon: isFetchingInSheet
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          isFetchingInSheet
                              ? l10n.text('fetching_location')
                              : l10n.text('use_my_current_location'),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.text('house_street_area'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: landmarkController,
                      decoration: InputDecoration(
                        labelText: l10n.text('landmark'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityController,
                            decoration: InputDecoration(
                              labelText: l10n.text('city'),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.text('pincode'),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final address = addressController.text.trim();
                          final areaCity = cityController.text.trim();
                          final pin = pincodeController.text.trim();
                          final needsPincode = selectedType != 'current_location';

                          if (address.isEmpty || areaCity.isEmpty || (needsPincode && pin.isEmpty)) {
                            await _showPopup(
                              title: l10n.text('delivery_address'),
                              message: l10n.text('please_complete_address'),
                            );
                            return;
                          }

                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                              'deliveryType': selectedType,
                              'fullAddress': address,
                              'landmark': landmarkController.text.trim(),
                              'city': areaCity,
                              'pincode': pin,
                            }, SetOptions(merge: true));
                          }

                          if (!mounted) return;

                          setState(() {
                            deliveryType = selectedType;
                            fullAddress = address;
                            landmark = landmarkController.text.trim();
                            city = areaCity;
                            pincode = pin;
                          });

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(l10n.text('save_delivery_address')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, String>?> _fetchCurrentLocationData() async {
    try {
      setState(() => isFetchingLocation = true);

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!kIsWeb) {
          await Geolocator.openLocationSettings();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.text('enable_location_services'))),
          );
        }
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.text('location_permission_denied'))),
          );
        }
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.text('location_permission_denied_forever')),
              action: SnackBarAction(
                label: context.l10n.text('settings'),
                onPressed: () {
                  Geolocator.openAppSettings();
                },
              ),
            ),
          );
        }
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (kIsWeb) {
        return {
          'fullAddress':
              'Latitude: ${position.latitude.toStringAsFixed(6)}, Longitude: ${position.longitude.toStringAsFixed(6)}',
          'landmark': context.l10n.text('current_location'),
          'city': context.l10n.text('current_location'),
          'pincode': '',
        };
      }

      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          return {
            'fullAddress': [
              placemark.subLocality,
              placemark.street,
              placemark.name,
            ].where((part) => part != null && part.trim().isNotEmpty).join(', '),
            'landmark': [
              placemark.locality,
              placemark.administrativeArea,
            ].where((part) => part != null && part.trim().isNotEmpty).join(', '),
            'city': placemark.locality?.trim().isNotEmpty == true
                ? placemark.locality!
                : (placemark.administrativeArea ?? context.l10n.text('current_location')),
            'pincode': placemark.postalCode ?? '',
          };
        }
      } catch (e) {
        debugPrint('Reverse geocoding failed: $e');
      }

      return {
        'fullAddress':
            'Latitude: ${position.latitude.toStringAsFixed(6)}, Longitude: ${position.longitude.toStringAsFixed(6)}',
        'landmark': context.l10n.text('current_location'),
        'city': context.l10n.text('current_location'),
        'pincode': '',
      };
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.text('could_not_fetch_location')}: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => isFetchingLocation = false);
      }
    }
  }

  // 2. Function to remove item from Firestore and local UI
  Future<void> _removeItem(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String prodName = currentItems[index]['productName'];

    try {
      // Find the document in Firestore and delete it
      final querySnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: user.uid)
          .where('productName', isEqualTo: prodName)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        // Subtract the price of the removed item
        // Note: This assumes your map has 'totalPrice' or similar.
        // If not, we calculate using unitPrice * quantity
        int itemTotal = (currentItems[index]['quantity'] * 1500); // Using your fixed price 1500
        currentTotal -= itemTotal;
        currentItems.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$prodName removed from cart")),
      );
    } catch (e) {
      debugPrint("Error removing item: $e");
    }
  }

  Future<void> _handleFinalPayment(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (currentItems.isEmpty) {
      _showEmptyCartMessage();
      return;
    }
    if (_deliverySummary.isEmpty) {
      await _showPopup(
        title: context.l10n.text('delivery_address'),
        message: context.l10n.text('add_delivery_address_first'),
      );
      await _showAddressSheet();
      return;
    }

    try {
      setState(() => isSavingOrder = true);
      // 1. Fetch User Name from Firestore 'users' collection
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String userName = userDoc.data()?['name'] ?? "Unknown User";

      final cartSnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: user.uid)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc();

      // 2. Add 'userName' to the order document
      batch.set(orderRef, {
        'userId': user.uid,
        'userName': userName, // CRITICAL for Admin side filtering
        'products': currentItems,
        'totalAmount': currentTotal,
        'deliveryType': deliveryType,
        'deliveryAddress': {
          'fullAddress': fullAddress,
          'landmark': landmark,
          'city': city,
          'pincode': pincode,
        },
        'status': 'Processing',
        'paymentStatus': 'Paid',
        'timestamp': FieldValue.serverTimestamp(),
      });

      for (var doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (context.mounted) {
        // 3. Navigate to the Success Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() => isSavingOrder = false);
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Order Placed!\nThe Revolve Agro team will contact you for delivery.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _contactSeller() async {
    final url = Uri.parse("tel:+917397820357");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: AppShell(
        colors: const [
          Color(0xFFE0EED2),
          Color(0xFFF7F3E8),
          Color(0xFFFFFBF4),
        ],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                AppPageHeader(
                  title: l10n.text('payment'),
                  subtitle: 'Review your order, confirm delivery details, and send it to the Revolve Agro team.',
                  badgeIcon: Icons.payments_outlined,
                  leading: IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  actions: const [
                    LanguageSelector(),
                  ],
                ),
                const SizedBox(height: 15),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        AppGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.text('order_summary'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Divider(),
                              if (currentItems.isEmpty)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    l10n.text('no_items_added_cart'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ...List.generate(currentItems.length, (index) {
                                final item = currentItems[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        "+${item['quantity']}",
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(item['productName'], style: const TextStyle(fontSize: 15)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: () => _removeItem(index),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(height: 30),
                              _buildSummaryRow(l10n.text('total_amount'), "Rs.$currentTotal/="),
                              _buildSummaryRow(l10n.text('delivery'), l10n.text('delivery_days')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        AppGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.text('delivery_address'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _showAddressSheet,
                                    child: Text(_deliverySummary.isEmpty ? l10n.text('add') : l10n.text('change')),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_deliverySummary.isEmpty)
                                Text(
                                  l10n.text('add_address_before_payment'),
                                  style: TextStyle(color: Colors.grey),
                                )
                              else ...[
                                Text(
                                  deliveryType == 'current_location'
                                      ? l10n.text('address_mode_current')
                                      : l10n.text('address_mode_manual'),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _deliverySummary,
                                  style: const TextStyle(height: 1.4),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        AppGlassCard(
                          child: Column(
                            children: [
                              Text(l10n.text('pay_via_card'), style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 15),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  "Total: Rs.$currentTotal/=",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _contactButton(),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSavingOrder ? null : () => _handleFinalPayment(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2991E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                    ),
                    child: isSavingOrder
                        ? const SizedBox(
                            height: 26,
                            width: 26,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : Text(l10n.text('pay_now'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // UI helper for contact button
  Widget _contactButton() {
    return InkWell(
      onTap: _contactSeller,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.text('contact_seller'), style: const TextStyle(fontWeight: FontWeight.w500)),
            const Icon(Icons.phone, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
