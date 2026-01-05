import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';

class ModernReservationCard extends StatelessWidget {
  final String patientName;
  final String phone;
  final DateTime date;
  final String status;
  final String? additionalInfo; // e.g. Grade level
  final String? notes;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;

  const ModernReservationCard({
    super.key,
    required this.patientName,
    required this.phone,
    required this.date,
    required this.status,
    this.additionalInfo,
    this.notes,
    this.onAccept,
    this.onReject,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // ... (keep color logic existing)
    // Determine status color/style
    Color statusColor;
    Color statusBg;
    String statusText = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted': // Handle accepted alias
        statusColor = Colors.green[700]!;
        statusBg = Colors.green[50]!;
        break;
      case 'rejected':
        statusColor = Colors.red[700]!;
        statusBg = Colors.red[50]!;
        break;
      case 'completed':
        statusColor = Colors.blue[700]!;
        statusBg = Colors.blue[50]!;
        break;
      default:
        statusColor = Colors.orange[700]!;
        statusBg = Colors.orange[50]!;
    }

    final formattedDate = DateFormat('MMM d, y').format(date);
    final formattedTime = DateFormat('h:mm a').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Darker shadow for dark mode
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar Placeholder (Gradient)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      patientName.isNotEmpty ? patientName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark, // Enforce dark mode text
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: AppColors.textSecondaryDark),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        ],
                      ),
                      if (additionalInfo != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.2), // Darker bg for tag
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                          ),
                          child: Text(
                            additionalInfo!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryLight, // Lighter text for contrast
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg.withOpacity(0.2), // More subtle transparent bg
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor, // Keep status color (green/red/orange)
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (notes != null && notes!.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.note, size: 16, color: AppColors.textSecondaryDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes!,
                      style: TextStyle(color: AppColors.textSecondaryDark, fontStyle: FontStyle.italic, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 1),
          
          // Details & Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Date/Time
                Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondaryDark),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.w500),
                ),
                // Only show time if it's meaningful (not default midnight)
                if (date.hour != 0 || date.minute != 0) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondaryDark),
                    const SizedBox(width: 8),
                    Text(
                      formattedTime,
                      style: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.w500),
                    ),
                ],
                
                const Spacer(),
                
                // Actions (Only if Pending)
                if (status.toLowerCase() == 'pending') ...[
                  TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accept', style: TextStyle(color: Colors.white)),
                  ),
                ] else if (onDelete != null)
                   Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      tooltip: 'Delete Reservation',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
