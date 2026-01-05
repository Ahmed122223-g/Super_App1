import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';
import 'package:jiwar_web/widgets/dialogs/success_dialog.dart';
import 'package:jiwar_web/widgets/dashboard/dashboard_stats_card.dart';
import 'package:jiwar_web/widgets/dashboard/modern_order_card.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';

class PharmacyOrdersTab extends StatefulWidget {
  const PharmacyOrdersTab({super.key});

  @override
  State<PharmacyOrdersTab> createState() => _PharmacyOrdersTabState();
}

class _PharmacyOrdersTabState extends State<PharmacyOrdersTab> {
  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final response = await _api.getOrders();
    if (response.isSuccess) {
      setState(() {
        _orders = response.data ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) ErrorDialog.show(context, errorCode: 'LOAD_ERROR', errorMessage: response.errorMessage);
    }
  }

  Future<void> _showPriceDialog(int orderId) async {
    final l10n = AppLocalizations.of(context)!;
    final priceController = TextEditingController();
    final deliveryController = TextEditingController(text: '0');
    final timeController = TextEditingController();
    final notesController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.setPrice),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.price),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deliveryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.deliveryFee),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: InputDecoration(labelText: l10n.estimatedTime),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: l10n.notes),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              _submitPrice(
                orderId,
                double.tryParse(priceController.text) ?? 0,
                double.tryParse(deliveryController.text) ?? 0,
                timeController.text,
                notesController.text
              );
            },
            child: Text(l10n.submit),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPrice(int id, double price, double delivery, String time, String notes) async {
    final l10n = AppLocalizations.of(context)!;
    if (price <= 0 || time.isEmpty) {
      ErrorDialog.show(context, errorCode: 'VALIDATION_ERROR', errorMessage: l10n.nameRequired);
      return;
    }

    final response = await _api.updateOrderPrice(
      id: id,
      totalPrice: price,
      deliveryFee: delivery,
      estimatedTime: time,
      notes: notes.isNotEmpty ? notes : null,
    );

    if (response.isSuccess) {
      if (mounted) {
        SuccessDialog.show(
          context,
          title: l10n.updateSuccess,
          message: l10n.updateSuccess,
          onDismiss: _loadData,
        );
      }
    } else {
      if (mounted) ErrorDialog.show(context, errorCode: 'UPDATE_ERROR', errorMessage: response.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final pendingCount = _orders.where((o) => o['status']?.toLowerCase() == 'pending').length;
    final pricedCount = _orders.where((o) => o['status']?.toLowerCase() == 'priced' || o['status']?.toLowerCase() == 'accepted').length;

    return Column(
      children: [
        // Stats
        Row(
          children: [
            Expanded(
              child: DashboardStatsCard(
                title: l10n.totalOrders,
                value: _orders.length.toString(),
                icon: Icons.receipt_long,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardStatsCard(
                title: l10n.newOrders,
                value: pendingCount.toString(),
                icon: Icons.notifications_active,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardStatsCard(
                title: l10n.processedOrders,
                value: pricedCount.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Header
        Row(
          children: [
            Text(
              l10n.orders,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          ],
        ),
        const SizedBox(height: 16),

        // List
        Expanded(
          child: _orders.isEmpty
            ? Center(child: Text(l10n.noOrders, style: TextStyle(fontSize: 18, color: Colors.grey[600])))
            : ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return ModernOrderCard(
                    orderId: order['id'],
                    customerName: order['customer_name'] ?? 'Guest',
                    customerPhone: order['customer_phone'] ?? '',
                    customerAddress: order['customer_address'] ?? 'Unknown Address',
                    date: DateTime.parse(order['created_at']),
                    status: order['status'] ?? 'pending',
                    price: order['total_price'] != null ? (order['total_price'] as num).toDouble() : null,
                    deliveryFee: order['delivery_fee'] != null ? (order['delivery_fee'] as num).toDouble() : null,
                    itemsText: order['items_text'],
                    prescriptionImage: order['prescription_image'],
                    estimatedTime: order['estimated_time'],
                    onAction: () {
                      if (order['status']?.toLowerCase() == 'accepted') {
                        _confirmDelivery(order['id']);
                      } else if (order['status']?.toLowerCase() == 'priced') {
                         // Already priced, maybe edit? For now do nothing or show info
                      } else {
                        _showPriceDialog(order['id']);
                      }
                    },
                    onDelete: (order['status']?.toLowerCase() == 'delivered' || 
                                order['status']?.toLowerCase() == 'rejected' ||
                                order['status']?.toLowerCase() == 'cancelled')
                        ? () => _onDelete(order['id']) 
                        : null,
                  );
                },
              ),
        ),
      ],
    );
  }

  Future<void> _confirmDelivery(int orderId) async {
    final l10n = AppLocalizations.of(context)!;
    // Simple confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'), // TODO: Localize
        content: const Text('Are you sure you want to mark this order as delivered?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _api.pharmacyOrderAction(id: orderId, action: 'deliver'); 
      if (response.isSuccess) {
        if (mounted) {
           SuccessDialog.show(context, title: 'Success', message: 'Order delivered', onDismiss: _loadData);
        }
      } else {
        if (mounted) ErrorDialog.show(context, errorCode: 'ACTION_FAILED', errorMessage: response.errorMessage);
      }
    }
  }

  Future<void> _onDelete(int orderId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true), 
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete')
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _api.deletePharmacyOrder(orderId);
      if (response.isSuccess) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order deleted successfully")));
           _loadData();
         }
      } else {
         if (mounted) ErrorDialog.show(context, errorCode: 'DELETE_ERROR', errorMessage: response.errorMessage);
      }
    }
  }
}
