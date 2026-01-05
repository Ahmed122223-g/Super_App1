import 'package:flutter/material.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:iconsax/iconsax.dart';

class TeacherScheduleDialog extends StatefulWidget {
  final Function(Map<String, List<String>>) onConfirm;

  const TeacherScheduleDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  State<TeacherScheduleDialog> createState() => _TeacherScheduleDialogState();
}

class _TeacherScheduleDialogState extends State<TeacherScheduleDialog> {
  final Map<String, List<String>> _schedule = {};
  
  final List<String> _days = [
    'Saturday', 'Sunday', 'Monday', 'Tuesday', 
    'Wednesday', 'Thursday', 'Friday'
  ];

  Map<String, String> _dayLabels = {
    'Saturday': 'السبت', 'Sunday': 'الأحد', 'Monday': 'الاثنين',
    'Tuesday': 'الثلاثاء', 'Wednesday': 'الأربعاء', 'Thursday': 'الخميس',
    'Friday': 'الجمعة'
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.calendar_add, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Text(
                  "تحديد مواعيد الحصة",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "حدد الأيام والساعات التي سيحضر فيها الطالب.",
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 24),

            // Days List
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: _days.map((day) => _buildDayItem(day)).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("إلغاء", style: TextStyle(color: AppColors.textSecondaryDark)),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _schedule.isEmpty ? null : () {
                    widget.onConfirm(_schedule);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
                  ),
                  child: const Text("تأكيد المواعيد"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayItem(String day) {
    final isSelected = _schedule.containsKey(day);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.dividerDark,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              _dayLabels[day]!,
              style: const TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold),
            ),
            trailing: Checkbox(
              value: isSelected,
              activeColor: AppColors.primary,
              side: BorderSide(color: AppColors.textSecondaryDark, width: 2),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _schedule[day] = []; // Initialize empty list
                  } else {
                    _schedule.remove(day);
                  }
                });
              },
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.dividerDark),
                  Row(
                    children: [
                      Text("الأوقات:", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 20),
                        onPressed: () => _addTimeSlot(day),
                        tooltip: "إضافة وقت",
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_schedule[day] ?? []).map((time) {
                      return Chip(
                        label: Text(time, style: const TextStyle(color: Colors.white)),
                        backgroundColor: AppColors.surfaceDark,
                        side: const BorderSide(color: AppColors.dividerDark),
                        deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.error),
                        onDeleted: () {
                          setState(() {
                            _schedule[day]?.remove(time);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addTimeSlot(String day) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceDark,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.surfaceDark,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format time (e.g., 10:00 AM)
      final localizations = MaterialLocalizations.of(context);
      final formattedTime = localizations.formatTimeOfDay(picked);
      
      setState(() {
        _schedule[day]?.add(formattedTime);
      });
    }
  }
}
