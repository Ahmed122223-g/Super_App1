import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';

class UserActivityCard extends StatelessWidget {
  final String title; // Provider Name
  final String subtitle; // Specialty or Items count
  final String type; // 'reservation' or 'order'
  final DateTime date;
  final String status;
  final double? price;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const UserActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.date,
    required this.status,
    this.price,
    this.onAccept,
    this.onReject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Fix: Add import if needed, assume provided by parent file imports or add import
    final isOrder = type == 'order';
    final statusColor = _getStatusColor(status);
    final statusBg = _getStatusBg(status);
    final formattedDate = DateFormat('MMM d, h:mm a').format(date);
    
    // Map status to localized string
    String statusText;
    switch (status.toLowerCase()) {
        case 'pending': statusText = l10n.statusPending; break;
        case 'confirmed': statusText = l10n.statusConfirmed; break;
        case 'completed': statusText = l10n.statusCompleted; break;
        case 'cancelled': statusText = l10n.statusCancelled; break;
        case 'rejected': statusText = l10n.statusRejected; break;
        case 'priced': statusText = l10n.statusPriced; break;
        case 'accepted': statusText = l10n.filterAccepted; break; // Reuse filter accepted or add statusAccepted? Use statusConfirmed/Accepted mismatch logic? Accepted usually means Confirmed.
        default: statusText = status.toUpperCase();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isOrder ? Colors.purple[900] : Colors.blue[900],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isOrder ? Iconsax.receipt_15 : Iconsax.calendar_15,
                        color: isOrder ? Colors.purple[300] : Colors.blue[300],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Title/Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                // Footer Info
                Row(
                  children: [
                    Icon(Iconsax.clock, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    
                    // Price for Orders
                    if (price != null) ...[
                      Text(
                        '${price} EGP',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Action Buttons for Priced Orders
                if (status.toLowerCase() == 'priced') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(l10n.reject),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: onAccept,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(l10n.acceptPrice),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
      case 'completed':
        return Colors.green[300]!;
      case 'rejected':
      case 'cancelled':
        return Colors.red[300]!;
      case 'priced':
        return Colors.purple[300]!;
      case 'pending':
      default:
        return Colors.orange[300]!;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
      case 'completed':
        return Colors.green[900]!;
      case 'rejected':
      case 'cancelled':
        return Colors.red[900]!;
      case 'priced':
        return Colors.purple[900]!;
      case 'pending':
      default:
        return Colors.orange[900]!;
    }
  }
}
