import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';
import 'package:jiwar_web/widgets/dialogs/success_dialog.dart';
import 'package:jiwar_web/widgets/dashboard/dashboard_stats_card.dart';
import 'package:jiwar_web/widgets/dashboard/modern_reservation_card.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';

class DoctorReservationsTab extends StatefulWidget {
  const DoctorReservationsTab({super.key});

  @override
  State<DoctorReservationsTab> createState() => _DoctorReservationsTabState();
}

class _DoctorReservationsTabState extends State<DoctorReservationsTab> {
  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _reservations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final response = await _api.getReservations();
    if (response.isSuccess) {
      setState(() {
        _reservations = response.data ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorDialog.show(context, errorCode: 'LOAD_ERROR', errorMessage: response.errorMessage);
      }
    }
  }

  Future<void> _updateStatus(int id, String action) async {
    final l10n = AppLocalizations.of(context)!;
    final response = await _api.respondToReservation(id: id, action: action);
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
      if (mounted) {
        ErrorDialog.show(context, errorCode: 'UPDATE_ERROR', errorMessage: response.errorMessage);
      }
    }
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text("حذف الحجز", style: TextStyle(color: Colors.white)),
        content: const Text("هل أنت متأكد من حذف هذا الحجز نهائياً؟", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("حذف"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _api.deleteProviderReservation(id, 'doctor');
      if (response.isSuccess) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حذف الحجز بنجاح")));
           _loadData();
        }
      } else {
        if (mounted) ErrorDialog.show(context, errorCode: 'DELETE_ERROR', errorMessage: response.errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final pendingCount = _reservations.where((r) => r['status']?.toLowerCase() == 'pending').length;
    final confirmedCount = _reservations.where((r) => r['status']?.toLowerCase() == 'confirmed').length;

    return Column(
      children: [
        // Stats Row
        Row(
          children: [
            Expanded(
              child: DashboardStatsCard(
                title: l10n.totalReservations,
                value: _reservations.length.toString(),
                icon: Icons.people_outline,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardStatsCard(
                title: l10n.pendingReservations,
                value: pendingCount.toString(),
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardStatsCard(
                title: l10n.confirmedReservations,
                value: confirmedCount.toString(),
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // List Header
        Row(
          children: [
            Text(
              l10n.reservations,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: l10n.tryAgain,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // List
        Expanded(
          child: _reservations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noReservations,
                      style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _reservations.length,
                itemBuilder: (context, index) {
                  final res = _reservations[index];
                  final patientName = res['patient_name'] ?? 'Unknown';
                  final phone = res['phone'] ?? '';
                  final date = DateTime.parse(res['date']);
                  final status = res['status'] ?? 'pending';
                  
                  return ModernReservationCard(
                    patientName: patientName,
                    phone: phone,
                    date: date,
                    status: status,
                    onAccept: () => _updateStatus(res['id'], 'accept'),

                    onReject: () => _handleReject(res['id']),
                    onDelete: (status.toLowerCase() == 'rejected' || status.toLowerCase() == 'completed' || status.toLowerCase() == 'cancelled') 
                        ? () => _onDelete(res['id']) 
                        : null,
                  );
                },
              ),
        ),
      ],
    );
  }

  Future<void> _handleReject(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text("رفض الحجز", style: TextStyle(color: Colors.white)),
        content: const Text("هل أنت متأكد من رفض هذا الحجز؟", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("إلغاء")
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("رفض الحجز"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateStatus(id, 'reject');
    }
  }
}
