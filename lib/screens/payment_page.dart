import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // 🔥 ADDED THIS IMPORT
import '../app_localizations.dart';
import '../widgets/app_shell.dart';
import '../widgets/language_selector.dart';
import 'PaymentSuccessScreen.dart';

class PaymentPage extends StatefulWidget {
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
  String paymentMethod = 'online'; // Default to online
  // The base amount (Total of products)
  int get _subtotal => currentTotal;

// 5% GST calculation
  int get _gstAmount => (_subtotal * 0.05).round();

// Final amount to be paid
  int get _finalTotal => _subtotal + _gstAmount;

  late Razorpay _razorpay; // 🔥 Razorpay Instance


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

    // 🔥 Initialize Razorpay Listeners
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
  }

  @override
  void dispose() {
    _razorpay.clear(); // 🔥 Cleanup
    super.dispose();
  }

  // 🔥 RAZORPAY HANDLERS
  void _handleRazorpaySuccess(PaymentSuccessResponse response) {
    _saveOrderToFirestore(); // Only save to DB if payment succeeds
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}"), backgroundColor: Colors.red),
    );
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
                    _buildPaymentMethodCard(l10n),
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

    final item = currentItems[index];
    final String prodName = item['productName']?.toString() ?? '';
    final String? prodId = item['productId']?.toString();
    final int qty = (item['quantity'] as num).toInt();
    final int unitPrice = (item['unitPrice'] as num?)?.toInt() ??
        ((item['totalPrice'] as num?)?.toInt() ?? (1500 * qty));
    final int itemTotal =
        (item['totalPrice'] as num?)?.toInt() ?? (unitPrice * qty);

    try {
      // Find the document in Firestore and delete it
      QuerySnapshot<Map<String, dynamic>> querySnapshot;
      final cartQuery = FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: user.uid);

      if (prodId != null && prodId.isNotEmpty) {
        querySnapshot = await cartQuery.where('productId', isEqualTo: prodId).get();
      } else {
        querySnapshot = await cartQuery.where('productName', isEqualTo: prodName).get();
      }

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
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

  Future<void> _decrementInventoryForOrder() async {
    final Map<String, int> productIdToQty = {};

    for (final item in currentItems) {
      final pid = item['productId']?.toString();
      if (pid == null || pid.isEmpty) continue;

      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
      if (qty <= 0) continue;

      productIdToQty[pid] = (productIdToQty[pid] ?? 0) + qty;
    }

    if (productIdToQty.isEmpty) return;

    for (final entry in productIdToQty.entries) {
      final pid = entry.key;
      final qty = entry.value;

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final productRef = FirebaseFirestore.instance.collection('products').doc(pid);
        final productSnap = await txn.get(productRef);
        if (!productSnap.exists) return;

        final data = productSnap.data();
        final currentInvRaw = data?['inventoryQuantity'] ?? 0;
        final currentInv = currentInvRaw is num
            ? currentInvRaw.toInt()
            : int.tryParse(currentInvRaw.toString()) ?? 0;

        final nextInv = (currentInv - qty) < 0 ? 0 : currentInv - qty;

        txn.update(productRef, {
          'inventoryQuantity': nextInv,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    }
  }


  void _handleFinalPayment(BuildContext context) async {
    if (currentItems.isEmpty) return _showEmptyCartMessage();
    if (_deliverySummary.isEmpty) {
      await _showPopup(title: "Address", message: "Add delivery address first");
      return _showAddressSheet();
    }

    // 🔥 CHECK FOR COD OR ONLINE
    if (paymentMethod == 'cod') {
      _saveOrderToFirestore(paymentStatus: 'Pending (COD)');
    } else {
      // 💳 ONLINE RAZORPAY FLOW
      var options = {
        'key': 'rzp_test_SaVqdvBWdnQSMU',
        'amount': _finalTotal * 100,
        'name': 'Revolve Agro',
        'prefill': {
          // 🔥 Ensure these are NEVER null
          'contact': FirebaseAuth.instance.currentUser?.phoneNumber ?? '8421059196',
          'email': FirebaseAuth.instance.currentUser?.email ?? 'test@revolveagro.com'
        },
        'external': {
          'wallets': ['paytm', 'gpay', 'phonepe']
        },
        // 🔥 UPI Intent force for Android
        'config': {
          'display': {
            'blocks': {
              'utp': {
                'name': 'Pay via UPI',
                'instruments': [
                  {'method': 'upi'}
                ],
              },
            },
            'sequence': ['block.utp', 'block.other'],
            'preferences': {'show_default_blocks': true},
          },
        },
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint("Razorpay Error: $e");
      }
    }
  }

// 🔥 UPDATE: Added {String paymentStatus = 'Paid'} to the signature
  Future<void> _saveOrderToFirestore({String paymentStatus = 'Paid'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => isSavingOrder = true);

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String userName = userDoc.data()?['name'] ?? "Unknown User";
      String userEmail = user.email ?? "Unknown Email";

      final cartSnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: user.uid)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc();

      // Calculate GST for the database record
      int gst = (currentTotal * 0.05).round();
      int finalTotal = currentTotal + gst;

      batch.set(orderRef, {
        'userId': user.uid,
        'userName': userName,
        'userEmail': userEmail,
        'products': currentItems,
        'subtotal': currentTotal,         // Base price
        'gstAmount': gst,                // 🔥 5% GST
        'totalAmount': finalTotal,       // 🔥 Final Price
        'deliveryType': deliveryType,
        'deliveryAddress': {
          'fullAddress': fullAddress,
          'landmark': landmark,
          'city': city,
          'pincode': pincode,
        },
        'status': 'pending',
        'paymentMethod': paymentMethod,  // 'online' or 'cod'
        'paymentStatus': paymentStatus,  // 🔥 Uses 'Paid' or 'Pending (COD)'
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (var doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      await _decrementInventoryForOrder();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isSavingOrder = false);
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
        colors: const [Color(0xFFE0EED2), Color(0xFFF7F3E8), Color(0xFFFFFBF4)],
        child: SafeArea(
          child: Padding(

            padding: const EdgeInsets.symmetric(horizontal: 20.0),

            child: Column(
              children: [
                const SizedBox(height: 20),
                AppPageHeader(
                  title: l10n.text('payment'),
                  subtitle: 'Review your order and pay securely.',
                  badgeIcon: Icons.payments_outlined,
                  leading: IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                  actions: const [LanguageSelector()],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildOrderSummaryCard(l10n),
                        const SizedBox(height: 15),
                        _buildAddressCard(l10n),
                        const SizedBox(height: 15),
                        _buildPriceCard(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _contactButton(),
                const SizedBox(height: 15),
                _buildPayButton(l10n),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(l10n) {
    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.text('order_summary'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          ...List.generate(currentItems.length, (index) {
            final item = currentItems[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text("+${item['quantity']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              title: Text(item['productName']),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeItem(index)),
            );
          }),
          const Divider(),
          _buildSummaryRow(l10n.text('total_amount'), "Rs.$currentTotal/="),
        ],
      ),
    );
  }

  Widget _buildAddressCard(l10n) {
    return AppGlassCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.text('delivery_address'), style: const TextStyle(fontWeight: FontWeight.bold))),
              TextButton(onPressed: _showAddressSheet, child: Text(_deliverySummary.isEmpty ? l10n.text('add') : l10n.text('change'))),
            ],
          ),
          Text(_deliverySummary.isEmpty ? l10n.text('add_address_before_payment') : _deliverySummary),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(l10n) {
    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              l10n.text('payment_method') ?? "Select Payment Method",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
          const Divider(),
          RadioListTile<String>(
            title: const Text("Online Payment"),
            subtitle: const Text("UPI, Cards, Netbanking"),
            value: 'online',
            groupValue: paymentMethod, // Ensure you declared: String paymentMethod = 'online';
            activeColor: const Color(0xFF2F6A3E),
            onChanged: (val) => setState(() => paymentMethod = val!),
          ),
          RadioListTile<String>(
            title: const Text("Cash on Delivery"),
            subtitle: const Text("Pay when you receive the order"),
            value: 'cod',
            groupValue: paymentMethod,
            activeColor: const Color(0xFF2F6A3E),
            onChanged: (val) => setState(() => paymentMethod = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Price Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          _buildSummaryRow("Subtotal", "₹$_subtotal"),
          _buildSummaryRow("GST (5%)", "₹$_gstAmount"), // 🔥 Added GST Row
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Payable", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("₹$_finalTotal", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF183020))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSavingOrder ? null : () => _handleFinalPayment(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF2991E),
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: isSavingOrder
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          // 🔥 Dynamic Label
            paymentMethod == 'cod' ? "PLACE ORDER (COD)" : l10n.text('pay_now'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
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
