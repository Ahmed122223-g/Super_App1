import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';
import 'package:jiwar_web/widgets/dialogs/success_dialog.dart';
import 'package:jiwar_web/widgets/dialogs/teacher_schedule_dialog.dart';
import 'package:jiwar_web/widgets/dashboard/dashboard_stats_card.dart';
import 'package:jiwar_web/widgets/dashboard/modern_reservation_card.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';

class TeacherReservationsTab extends StatefulWidget {
  const TeacherReservationsTab({super.key});

  @override
  State<TeacherReservationsTab> createState() => _TeacherReservationsTabState();
}

class _TeacherReservationsTabState extends State<TeacherReservationsTab> {
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
      if (mounted) {
        setState(() {
          _reservations = response.data ?? [];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDialog.show(context, errorCode: 'LOAD_ERROR', errorMessage: response.errorMessage);
      }
    }
  }

  // --- Actions ---

  Future<void> _onAccept(int id) async {
    // Show Schedule Dialog
    showDialog(
      context: context,
      builder: (context) => TeacherScheduleDialog(
        onConfirm: (schedule) {
          _updateStatus(id, 'accept', schedule: schedule);
        },
      ),
    );
  }

  Future<void> _onReject(int id) async {
    // Show Confirmation Dialog
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text("رفض الحجز", style: TextStyle(color: Colors.white)),
        content: Text("هل أنت متأكد من رفض هذا الطلب؟ \nسيتم إرسال إشعار للمستخدم.", style: TextStyle(color: Colors.grey[300])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("إلغاء", style: TextStyle(color: Colors.grey[400])),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text("رفض الحجز"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _updateStatus(id, 'reject', reason: "Rejected by teacher");
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
      final response = await _api.deleteProviderReservation(id, 'teacher');
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


  Future<void> _updateStatus(int id, String action, {String? reason, Map<String, List<String>>? schedule}) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Show loading indicator overlay if needed, or just handle async
    // Here we assume quick response or optimistic update could be better, but let's stick to simple await for now
    
    final response = await _api.respondToReservation(
      id: id, 
      action: action,
      reason: reason,
      schedule: schedule
    );

    if (response.isSuccess) {
      if (mounted) {
        SuccessDialog.show(
          context,
          title: l10n.updateSuccess,
          message: action == 'accept' 
              ? "تم قبول الحجز وتحديد المواعيد بنجاح!" 
              : "تم رفض الحجز وإبلاغ المستخدم.",
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

    final pendingCount = _reservations.where((r) => r['status']?.toLowerCase() == 'pending').length;
    final confirmedCount = _reservations.where((r) => r['status']?.toLowerCase() == 'confirmed').length;

    return Column(
      children: [
        // Stats
        Row(
          children: [
            Expanded(
              child: DashboardStatsCard(
                title: l10n.totalReservations,
                value: _reservations.length.toString(),
                icon: Icons.school,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardStatsCard(
                title: l10n.pendingReservations,
                value: pendingCount.toString(),
                icon: Icons.notifications_active,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardStatsCard(
                title: l10n.acceptedReservations,
                value: confirmedCount.toString(),
                icon: Icons.check_circle,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Header
        Row(
          children: [
            Text(
              l10n.reservations,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary), 
              onPressed: _loadData
            ),
          ],
        ),
        const SizedBox(height: 16),

        // List
        Expanded(
          child: _reservations.isEmpty
            ? Center(child: Text(l10n.noReservations, style: const TextStyle(fontSize: 18, color: AppColors.textSecondaryDark)))
            : ListView.builder(
                itemCount: _reservations.length,
                itemBuilder: (context, index) {
                  final res = _reservations[index];
                  final studentName = res['student_name'] ?? 'Unknown Student';
                  final phone = res['phone'] ?? res['student_phone'] ?? '';
                  final dateStr = res['requested_date'] ?? res['date'];
                  final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
                  final status = res['status'] ?? 'pending';
                  final gradeLevel = res['grade_level'];
                  final notes = res['notes'];

                  return ModernReservationCard(
                    patientName: studentName,
                    date: date,
                    // time: "Any time", // Removed as not supported
                    status: status,
                    onAccept: status.toLowerCase() == 'pending' ? () => _onAccept(res['id']) : null,
                    onReject: status.toLowerCase() == 'pending' ? () => _onReject(res['id']) : null,
                    // Show Delete for final states
                    onDelete: (status.toLowerCase() == 'rejected' || status.toLowerCase() == 'completed' || status.toLowerCase() == 'cancelled') 
                        ? () => _onDelete(res['id']) 
                        : null,
                    notes: notes,
                    additionalInfo: "Student Grade: ${gradeLevel ?? 'N/A'}",
                    phone: phone,
                  );
                },
              ),
        ),
      ],
    );
  }
}
