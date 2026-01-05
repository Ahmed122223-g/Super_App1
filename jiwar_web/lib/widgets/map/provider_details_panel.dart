import 'package:flutter/material.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:jiwar_web/pages/dashboard/user/user_map_page.dart';
import 'package:jiwar_web/pages/booking/doctor_booking_dialog.dart';
import 'package:jiwar_web/pages/orders/pharmacy_order_dialog.dart';
import 'package:jiwar_web/widgets/dialogs/rating_dialog.dart';
import 'package:jiwar_web/widgets/map/ratings_sheet.dart';
import 'package:jiwar_web/pages/booking/teacher_booking_dialog.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Side panel showing provider details when a marker is tapped
class ProviderDetailsPanel extends StatelessWidget {
  final MapProviderData provider;
  final VoidCallback onClose;
  final VoidCallback onRefresh;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const ProviderDetailsPanel({
    super.key,
    required this.provider,
    required this.onClose,
    required this.onRefresh,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  Color get _typeColor {
    switch (provider.type) {
      case 'doctor': return const Color(0xFF2196F3);
      case 'pharmacy': return const Color(0xFF4CAF50);
      case 'teacher': return const Color(0xFF9C27B0);
      default: return Colors.grey;
    }
  }

  IconData get _typeIcon {
    switch (provider.type) {
      case 'doctor': return Icons.local_hospital;
      case 'pharmacy': return Icons.local_pharmacy;
      case 'teacher': return Icons.school;
      default: return Icons.location_on;
    }
  }

  /// Helper to construct full image URL
  String _getFullImageUrl(String path) {
    // If already a full URL, return as-is
    if (path.startsWith('http')) return path;
    // Otherwise, prepend staticUrl
    return ApiService.staticUrl + path;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final secondaryTextColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Material(
      elevation: 16,
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_typeColor, _typeColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const Spacer(),
                      // Favorite Button
                      IconButton(
                        onPressed: onFavoriteToggle,
                        icon: Icon(
                          isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isFavorite ? Colors.amber : Colors.white,
                          size: 28,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(_typeIcon, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _getTypeLabel(l10n),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Profile Image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: surfaceColor,
                      image: provider.profileImage != null && provider.profileImage!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_getFullImageUrl(provider.profileImage!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: provider.profileImage == null || provider.profileImage!.isEmpty
                        ? Icon(_typeIcon, size: 48, color: _typeColor)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  
                  // Name
                  Text(
                    provider.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (provider.specialty != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      provider.specialty!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  
                  // Rating
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(5, (index) {
                          final starValue = index + 1;
                          if (provider.rating >= starValue) {
                            return const Icon(Icons.star, color: Colors.amber, size: 20);
                          } else if (provider.rating >= starValue - 0.5) {
                            return const Icon(Icons.star_half, color: Colors.amber, size: 20);
                          } else {
                            return const Icon(Icons.star_border, color: Colors.amber, size: 20);
                          }
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${provider.rating.toStringAsFixed(1)} (${provider.totalRatings})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address
                    _buildInfoRow(Icons.location_on, l10n.address, provider.address, secondaryTextColor, textColor),
                    const SizedBox(height: 16),
                    
                    // Phone
                    if (provider.phone != null && provider.phone!.isNotEmpty)
                      _buildInfoRow(Icons.phone, l10n.phone, provider.phone!, secondaryTextColor, textColor),
                    if (provider.phone != null && provider.phone!.isNotEmpty)
                      const SizedBox(height: 16),
                    
                    // Examination Fee (for doctors)
                    if (provider.type == 'doctor' && provider.examinationFee != null)
                      _buildInfoRow(
                        Icons.local_hospital,
                        Localizations.localeOf(context).languageCode == 'ar' ? 'سعر الكشف' : 'Examination Fee',
                        '${provider.examinationFee} EGP',
                        secondaryTextColor, textColor
                      ),
                    if (provider.type == 'doctor' && provider.examinationFee != null)
                      const SizedBox(height: 12),
                    
                    // Consultation Fee (for doctors)
                    if (provider.type == 'doctor' && provider.consultationFee != null)
                      _buildInfoRow(
                        Icons.chat,
                        Localizations.localeOf(context).languageCode == 'ar' ? 'سعر الاستشارة' : 'Consultation Fee',
                        '${provider.consultationFee} EGP',
                        secondaryTextColor, textColor
                      ),
                    if (provider.type == 'doctor' && (provider.consultationFee != null || provider.examinationFee != null))
                      const SizedBox(height: 16),
                    
                    // Working Hours (for doctors)
                    if (provider.type == 'doctor' && provider.workingHours != null)
                      _buildWorkingHoursRow(l10n, secondaryTextColor, textColor),
                    if (provider.type == 'doctor' && provider.workingHours != null)
                      const SizedBox(height: 16),
                    
                    // Delivery (for pharmacies)
                    if (provider.type == 'pharmacy' && provider.deliveryAvailable != null)
                      _buildInfoRow(
                        Icons.delivery_dining,
                        l10n.deliveryAvailable,
                        provider.deliveryAvailable! ? l10n.yes : l10n.no,
                        secondaryTextColor, textColor
                      ),
                    if (provider.type == 'pharmacy' && provider.deliveryAvailable != null)
                      const SizedBox(height: 16),
                    
                    // Working Hours (for pharmacies)
                    if (provider.type == 'pharmacy' && provider.workingHours != null)
                      _buildWorkingHoursRow(l10n, secondaryTextColor, textColor),
                    if (provider.type == 'pharmacy' && provider.workingHours != null)
                      const SizedBox(height: 16),
                    
                    // Description
                    if (provider.description != null && provider.description!.isNotEmpty) ...[
                      Text(
                        l10n.description,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.description!,
                        style: TextStyle(color: secondaryTextColor, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Book Appointment Button (for doctors)
                  if (provider.type == 'doctor' && (provider.examinationFee != null || provider.consultationFee != null))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => DoctorBookingDialog(
                              doctorId: provider.id,
                              doctorName: provider.name,
                              specialty: provider.specialty ?? '',
                              examinationFee: provider.examinationFee,
                              consultationFee: provider.consultationFee,
                            ),
                          ),
                          icon: const Icon(Icons.calendar_month, color: Colors.white),
                          label: Text(
                            Localizations.localeOf(context).languageCode == 'ar' 
                              ? 'حجز موعد' 
                              : 'Book Appointment',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),

                  // Order Treatment Button (for pharmacies with delivery)
                  if (provider.type == 'pharmacy' && provider.deliveryAvailable == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => PharmacyOrderDialog(
                              pharmacyId: provider.id,
                              pharmacyName: provider.name,
                            ),
                          ),
                          icon: const Icon(Icons.delivery_dining, color: Colors.white),
                          label: Text(
                            Localizations.localeOf(context).languageCode == 'ar' 
                              ? 'اطلب الآن' 
                              : 'Order Now',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  
                    // Request Lesson Button (for teachers)
                    if (provider.type == 'teacher')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              // Extract available grades from pricing
                              final List<Map<String, dynamic>> availableGrades = [];
                              if (provider.pricing != null) {
                                for (var price in provider.pricing!) {
                                  if (price['grade_name'] != null) {
                                    availableGrades.add({
                                      'grade': price['grade_name'].toString(),
                                      'price': price['price'] // could be double or int
                                    });
                                  }
                                }
                              }
                              
                              // Fallback if no specific grades found (no price)
                              if (availableGrades.isEmpty) {
                                availableGrades.addAll([
                                  {'grade': 'المرحلة الابتدائية', 'price': null},
                                  {'grade': 'المرحلة الإعدادية', 'price': null}, 
                                  {'grade': 'المرحلة الثانوية', 'price': null}
                                ]);
                              }

                              showDialog(
                                context: context,
                                builder: (context) => TeacherBookingDialog(
                                  teacherId: provider.id,
                                  teacherName: provider.name,
                                  availableGrades: availableGrades,
                                ),
                              );
                            },
                            icon: const Icon(Icons.school, color: Colors.white),
                            label: Text(
                              Localizations.localeOf(context).languageCode == 'ar' 
                                ? 'طلب حجز درس' 
                                : 'Request Lesson',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),

                    // WhatsApp Button (for teachers with whatsapp number)
                    if (provider.type == 'teacher' && provider.whatsapp != null && provider.whatsapp!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _openWhatsApp(provider.whatsapp!),
                            icon: const Icon(Icons.whatshot, color: Colors.white), // Using whatshot as placeholder if chat icon not available
                            label: Text(
                              Localizations.localeOf(context).languageCode == 'ar' 
                                ? 'تواصل عبر واتساب' 
                                : 'Chat on WhatsApp',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                  
                  // Rate Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showRatingDialog(context),
                      icon: const Icon(Icons.star),
                      label: Text(l10n.addRating),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // View Ratings Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRatingsSheet(context),
                      icon: const Icon(Icons.reviews),
                      label: Text(l10n.viewRatings),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor, // Use theme text color
                        side: BorderSide(color: isDark ? Colors.white54 : Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(AppLocalizations l10n) {
    switch (provider.type) {
      case 'doctor': return l10n.doctors;
      case 'pharmacy': return l10n.pharmacies;
      case 'teacher': return l10n.teachers;
      default: return provider.type;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color labelColor, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _typeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: labelColor, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: valueColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingHoursRow(AppLocalizations l10n, Color labelColor, Color valueColor) {
    final hours = provider.workingHours!;
    final isArabic = l10n.localeName == 'ar';
    
    // Get time range
    final start = hours['start'] ?? '09:00';
    final end = hours['end'] ?? '21:00';
    
    // Get working days
    final daysMap = hours['days'] as Map<String, dynamic>?;
    final dayNames = isArabic 
      ? {'saturday': 'السبت', 'sunday': 'الأحد', 'monday': 'الإثنين', 'tuesday': 'الثلاثاء', 'wednesday': 'الأربعاء', 'thursday': 'الخميس', 'friday': 'الجمعة'}
      : {'saturday': 'Sat', 'sunday': 'Sun', 'monday': 'Mon', 'tuesday': 'Tue', 'wednesday': 'Wed', 'thursday': 'Thu', 'friday': 'Fri'};
    
    final workingDays = <String>[];
    if (daysMap != null) {
      for (final entry in daysMap.entries) {
        if (entry.value == true && dayNames.containsKey(entry.key)) {
          workingDays.add(dayNames[entry.key]!);
        }
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.access_time, color: _typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.workingHours,
                    style: TextStyle(color: labelColor, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$start - $end',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: valueColor),
                  ),
                  if (workingDays.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      workingDays.join(' • '),
                      style: TextStyle(color: labelColor, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openWhatsApp(String phoneNumber) {
    // Clean phone number (remove spaces, dashes, etc.)
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // If number starts with 0, replace with Egypt country code
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '+20${cleanNumber.substring(1)}';
    }
    
    final url = 'https://wa.me/$cleanNumber';
    
    html.window.open(url, '_blank');
  }




  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        providerId: provider.id,
        providerType: provider.type,
        providerName: provider.name,
        onSuccess: onRefresh,
      ),
    );
  }

  void _showRatingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RatingsSheet(
        providerId: provider.id,
        providerType: provider.type,
        providerName: provider.name,
      ),
    );
  }
}
