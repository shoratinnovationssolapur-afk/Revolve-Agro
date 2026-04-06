import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/order_tracking_service.dart';

class AdminTrackingStatusDialog extends StatefulWidget {
  final String orderId;
  final String currentTrackingStatus;

  const AdminTrackingStatusDialog({
    required this.orderId,
    required this.currentTrackingStatus,
  });

  @override
  State<AdminTrackingStatusDialog> createState() =>
      _AdminTrackingStatusDialogState();
}

class _AdminTrackingStatusDialogState
    extends State<AdminTrackingStatusDialog> {
  late String selectedStatus;
  final trackingNumberController = TextEditingController();
  final notesController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.currentTrackingStatus;
    _loadTrackingDetails();
  }

  Future<void> _loadTrackingDetails() async {
    try {
      final details =
          await OrderTrackingService.getTrackingDetails(widget.orderId);
      if (details != null && mounted) {
        setState(() {
          trackingNumberController.text = details['trackingNumber'] ?? '';
          notesController.text = details['notes'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading tracking details: $e');
    }
  }

  Future<void> _updateTracking() async {
    if (selectedStatus == 'none') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tracking status')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await OrderTrackingService.updateTrackingStatus(
        orderId: widget.orderId,
        newStatus: selectedStatus,
        trackingNumber: trackingNumberController.text.trim().isNotEmpty
            ? trackingNumberController.text.trim()
            : null,
        notes: notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tracking status updated to ${selectedStatus.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    trackingNumberController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Tracking Status'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select tracking status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Processing'),
                  subtitle: const Text('Order is being processed'),
                  value: 'processing',
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() => selectedStatus = value ?? 'none');
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Shipped'),
                  subtitle: const Text('Order has been shipped'),
                  value: 'shipped',
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() => selectedStatus = value ?? 'none');
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Delivered'),
                  subtitle: const Text('Order has been delivered'),
                  value: 'delivered',
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() => selectedStatus = value ?? 'none');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: trackingNumberController,
              decoration: InputDecoration(
                labelText: 'Tracking Number (Optional)',
                hintText: 'e.g., NDSO123456789',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Delivery Notes (Optional)',
                hintText: 'Add any notes about the delivery...',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _updateTracking,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
