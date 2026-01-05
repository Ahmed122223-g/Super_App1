import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';

class ModernOrderCard extends StatelessWidget {
  final int orderId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final DateTime date;
  final String status;
  final double? price;
  final double? deliveryFee;
  final VoidCallback? onAction;
  final VoidCallback? onDelete;
  final String? itemsText;
  final String? prescriptionImage;
  final String? estimatedTime;

  const ModernOrderCard({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.date,
    required this.status,
    this.price,
    this.deliveryFee,
    this.onAction,
    this.onDelete,
    this.itemsText,
    this.prescriptionImage,
    this.estimatedTime,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBg;
    
    switch (status.toLowerCase()) {
      case 'priced':
        statusColor = AppColors.info;
        statusBg = AppColors.info.withOpacity(0.1);
        break;
      case 'accepted':
        statusColor = AppColors.success;
        statusBg = AppColors.success.withOpacity(0.1);
        break;
      case 'rejected':
      case 'cancelled':
        statusColor = AppColors.error;
        statusBg = AppColors.error.withOpacity(0.1);
        break;
      case 'delivered':
      case 'completed':
        statusColor = AppColors.primary;
        statusBg = AppColors.primary.withOpacity(0.1);
        break;
      default: // pending
        statusColor = AppColors.warning;
        statusBg = AppColors.warning.withOpacity(0.1);
    }

    final formattedDate = DateFormat('MMM d, h:mm a').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #$orderId',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                         children: [
                           Icon(Icons.person, size: 12, color: AppColors.textSecondaryDark),
                           const SizedBox(width: 4),
                           Text(
                             customerName,
                             style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                           ),
                         ]
                      )
                    ],
                  ),
                ),
                Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(
                         color: statusBg,
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: statusColor.withOpacity(0.3)),
                       ),
                       child: Text(
                         status.toUpperCase(),
                         style: TextStyle(
                           color: statusColor,
                           fontSize: 11,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       formattedDate,
                       style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                     ),
                   ],
                 ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Customer Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.textSecondaryDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customerAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: AppColors.textSecondaryDark),
                    const SizedBox(width: 8),
                    Text(
                      customerPhone,
                      style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Items / Prescription
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Details:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark)),
                const SizedBox(height: 8),
                  if (prescriptionImage != null && prescriptionImage!.isNotEmpty)
                   // If prescription, show button to view or thumbnail
                   Container(
                     width: double.infinity,
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: AppColors.backgroundDark,
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: AppColors.dividerDark),
                     ),
                     child: Row(
                       children: [
                         const Icon(Icons.image, color: AppColors.primary),
                         const SizedBox(width: 12),
                         const Expanded(child: Text("Prescription Attached", style: TextStyle(color: AppColors.textPrimaryDark))),
                         TextButton(
                           onPressed: () => _showPrescriptionImage(context, prescriptionImage!),
                           child: const Text("View"),
                         )
                       ],
                     ),
                   )
                else
                   const SizedBox.shrink(), // Fallback if image exists but logic was else-if

                if (itemsText != null && itemsText!.isNotEmpty) ...[
                   if (prescriptionImage != null && prescriptionImage!.isNotEmpty) const SizedBox(height: 12),
                   Text(
                     itemsText!,
                     style: TextStyle(fontSize: 14, color: AppColors.textPrimaryDark),
                   )
                ]
                else if (prescriptionImage == null || prescriptionImage!.isEmpty)
                   Text("No details provided", style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondaryDark)),
              ],
            ),
          ),

          const Divider(height: 1),
          
          // Custom Actions or Price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (price != null && price! > 0)
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           Text(
                             'Total: ${price!.toStringAsFixed(0)} EGP',
                             style: const TextStyle(
                               fontWeight: FontWeight.bold,
                               fontSize: 16,
                               color: AppColors.primary,
                             ),
                           ),
                           if (deliveryFee != null)
                             Text(" (+${deliveryFee!.toStringAsFixed(0)} Del.)", style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark))
                         ],
                       ),
                       if (estimatedTime != null)
                         Text("Time: $estimatedTime", style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                     ],
                   )
                else
                  Text(
                    'Price Pending',
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontStyle: FontStyle.italic,
                      fontSize: 13
                    ),
                  ),
                const Spacer(),
                if ((status.toLowerCase() == 'pending' || status.toLowerCase() == 'accepted') && onAction != null)
                  ElevatedButton.icon(
                    onPressed: onAction,
                    icon: Icon(status.toLowerCase() == 'accepted' ? Icons.local_shipping : Icons.edit_note, size: 16),
                    label: Text(status.toLowerCase() == 'accepted' ? 'Deliver' : 'Set Price'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status.toLowerCase() == 'accepted' ? AppColors.success : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),

                if (onDelete != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      tooltip: 'Delete Order',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  child: _buildImage(imageUrl),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageData) {
    try {
      if (imageData.startsWith('http')) {
        return Image.network(
          imageData,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              width: 200,
              color: AppColors.surfaceDark,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        );
      } else {
        // Try Base64
        try {
          final bytes = base64Decode(imageData);
          return Image.memory(
            bytes, 
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
          );
        } catch (e) {
             // If Base64 fails, try as relative URL
             return Image.network(
                '${ApiService.staticUrl}$imageData',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
             );
        }
      }
    } catch (e) {
      return _buildErrorPlaceholder();
    }
    return _buildErrorPlaceholder();
  }
  
  Widget _buildErrorPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surfaceDark,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, color: AppColors.error, size: 48),
          SizedBox(height: 8),
          Text("Failed to load image", style: TextStyle(color: AppColors.textSecondaryDark)),
        ],
      ),
    );
  }
}
