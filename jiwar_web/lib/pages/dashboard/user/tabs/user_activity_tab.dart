import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/widgets/dashboard/user_activity_card.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';
import 'package:jiwar_web/widgets/dialogs/success_dialog.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';

class UserActivityTab extends StatefulWidget {
  const UserActivityTab({super.key});

  @override
  State<UserActivityTab> createState() => _UserActivityTabState();
}

class _UserActivityTabState extends State<UserActivityTab> {
  final _api = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];
  
  // Filters
  String _filterStatus = 'all'; // all, current, past, accepted, rejected
  String _filterType = 'all'; // all, doctor, pharmacy, teacher
  bool _sortNewest = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final reservationsRes = await _api.getMyReservations();
      final ordersRes = await _api.getMyOrders();

      if (reservationsRes.isSuccess && ordersRes.isSuccess) {
        final List<Map<String, dynamic>> loaded = [];

        // Process Reservations
        for (var r in (reservationsRes.data ?? [])) {
          String providerType = r['provider_type'] ?? 'doctor';
          String subtype = r['booking_type'] ?? (providerType == 'teacher' ? 'teacher_session' : 'consultation');
          loaded.add({
            'type': 'reservation',
            'providerType': providerType, // doctor or teacher
            'subtype': subtype,
            'data': r,
            'date': DateTime.parse(r['visit_date']),
            'status': r['status'],
          });
        }

        // Process Orders
        for (var o in (ordersRes.data ?? [])) {
          loaded.add({
            'type': 'order',
            'providerType': 'pharmacy',
            'subtype': 'pharmacy_order',
            'data': o,
            'date': DateTime.parse(o['created_at']),
            'status': o['status'],
          });
        }

        if (mounted) {
          setState(() {
            _activities = loaded;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ErrorDialog.show(context, errorCode: 'LOAD', errorMessage: 'Failed to load activities');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDialog.show(context, errorCode: 'ERROR', errorMessage: e.toString());
      }
    }
  }

  Future<void> _handleOrderAction(int id, String action) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await _api.respondToOrder(id: id, action: action);
    if (success.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(action == 'accept' ? l10n.orderAccepted : l10n.orderRejected)),
        );
        _loadData(); // Reload to refresh status
      }
    } else {
      if (mounted) {
        ErrorDialog.show(context, errorCode: 'ACTION', errorMessage: success.errorMessage);
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredActivities() {
    List<Map<String, dynamic>> filtered = List.from(_activities);

    // Filter by Type
    if (_filterType != 'all') {
      filtered = filtered.where((item) {
        return item['providerType'] == _filterType;
      }).toList();
    }

    // Filter by Status
    if (_filterStatus != 'all') {
      filtered = filtered.where((item) {
        final status = (item['status'] as String).toLowerCase();
        
        switch (_filterStatus) {
          case 'current':
            return ['pending', 'priced', 'confirmed', 'accepted'].contains(status);
          case 'past':
            return ['completed', 'cancelled'].contains(status);
          case 'rejected':
            return ['rejected', 'cancelled'].contains(status);
          case 'accepted':
            return ['confirmed', 'accepted'].contains(status);
          default:
            return true;
        }
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return _sortNewest ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    return filtered;
  }

  void _showOrderDetails(Map<String, dynamic> item) {
    final data = item['data'];
    final type = item['type'] as String;
    final providerType = item['providerType'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getTypeColor(providerType).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getTypeIcon(providerType), color: _getTypeColor(providerType)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type == 'order' ? (data['pharmacy_name'] ?? 'Pharmacy') : (data['provider_name'] ?? 'Provider'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          _getSubtypeLabel(providerType, item['subtype'] ?? ''),
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey, height: 1),
            // Details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildDetailsContent(type, providerType, data),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailsContent(String type, String providerType, Map<String, dynamic> data) {
    List<Widget> widgets = [];
    
    if (type == 'order') {
      // Pharmacy Order
      widgets.addAll([
        _buildDetailRow('رقم الطلب', '#${data['id']}'),
        _buildDetailRow('الحالة', data['status'] ?? '-'),
        _buildDetailRow('التاريخ', _formatDate(data['created_at'])),
        if (data['total_price'] != null) ...[
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: AppColors.primary.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: AppColors.primary),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text("عرض الصيدلية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                   const SizedBox(height: 12),
                   _buildDetailRow('سعر الأدوية', '${data['total_price']} جنيه'),
                   if (data['delivery_fee'] != null) ...[
                     _buildDetailRow('سعر التوصيل', '${data['delivery_fee']} جنيه'),
                     const Divider(color: Colors.grey, height: 20),
                     _buildDetailRow(
                       'الإجمالي', 
                       '${(double.tryParse(data['total_price'].toString()) ?? 0) + (double.tryParse(data['delivery_fee'].toString()) ?? 0)} جنيه'
                     ),
                   ],
                   if (data['estimated_time'] != null)
                     _buildDetailRow('الوقت المقدر', data['estimated_time']),
                   if (data['notes'] != null && data['notes'].toString().isNotEmpty)
                     _buildDetailRow('ملاحظات الصيدلية', data['notes']),
                   const SizedBox(height: 12),
                   if (data['status'] == 'priced')
                     Row(
                       children: [
                         Expanded(
                           child: OutlinedButton(
                             onPressed: () { 
                               Navigator.pop(context); // Close sheet
                               _handleOrderAction(data['id'], 'reject');
                             },
                             style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                             child: const Text("رفض"),
                           ),
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: FilledButton(
                             onPressed: () {
                               Navigator.pop(context);
                               _handleOrderAction(data['id'], 'accept');
                             },
                             style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                             child: const Text("موافقة"),
                           ),
                         ),
                       ],
                     ),
                 ],
               ),
             ),
             const SizedBox(height: 16),
        ],
        // Show items_text (medications entered by user)
        if (data['items_text'] != null && data['items_text'].toString().isNotEmpty) ...[
          const Text('الأدوية المطلوبة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(data['items_text'], style: TextStyle(color: Colors.grey[300])),
          ),
          const SizedBox(height: 16),
        ],
        // Show prescription image if available
        if (data['prescription_image'] != null && data['prescription_image'].toString().isNotEmpty) ...[
          const Text('صورة الروشتة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildPrescriptionImage(data['prescription_image'].toString()),
          ),
          const SizedBox(height: 16),
        ],
      ]);
    } else {
      widgets.addAll([
        _buildDetailRow('رقم الحجز', '#${data['id']}'),
        _buildDetailRow('الحالة', data['status'] ?? '-'),
        _buildDetailRow('تاريخ الزيارة', _formatDate(data['visit_date'])),
        if (data['visit_time'] != null) _buildDetailRow('وقت الزيارة', data['visit_time']),
        if (providerType == 'doctor') ...[
          if (data['specialty'] != null) _buildDetailRow('التخصص', data['specialty']),
          _buildDetailRow('نوع الحجز', data['booking_type'] == 'examination' ? 'كشف' : 'استشارة'),
        ],
        if (providerType == 'teacher') ...[
          if (data['subject'] != null) _buildDetailRow('المادة', data['subject']),
          if (data['grade'] != null) _buildDetailRow('المرحلة', data['grade']),
        ],
        if (type == 'reservation' && providerType == 'teacher' && data['schedule'] != null) ...[
             const SizedBox(height: 16),
             const Text('جدول الحصص:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
             const SizedBox(height: 8),
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: Colors.grey[800],
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: AppColors.primary.withOpacity(0.3)),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: (data['schedule'] as Map<String, dynamic>).entries.map((entry) {
                    final dayMap = {
                      'Saturday': 'السبت', 'Sunday': 'الأحد', 'Monday': 'الاثنين',
                      'Tuesday': 'الثلاثاء', 'Wednesday': 'الأربعاء', 'Thursday': 'الخميس',
                      'Friday': 'الجمعة'
                    };
                    final dayName = dayMap[entry.key] ?? entry.key;
                    // Handle dynamic list or list of strings
                    final timesList = (entry.value as List).map((e) => e.toString()).toList();
                    final times = timesList.join('، ');
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('$dayName: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          Expanded(child: Text(times, style: TextStyle(color: Colors.grey[300]))),
                        ],
                      ),
                    );
                 }).toList(),
               ),
             ),
             const SizedBox(height: 16),
        ],
        if (data['notes'] != null && data['notes'].toString().isNotEmpty)
          _buildDetailRow('ملاحظات', data['notes']),
      ]);
    }
    
    return widgets;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[400])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildPrescriptionImage(String imageData) {
    try {
      // Check if it's a URL or base64
      if (imageData.startsWith('http')) {
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          height: 200,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildImageError(),
        );
      } else {
        // It's base64 data
        final bytes = base64Decode(imageData);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          height: 200,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildImageError(),
        );
      }
    } catch (e) {
      return _buildImageError();
    }
  }

  Widget _buildImageError() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'doctor': return Colors.blue;
      case 'pharmacy': return Colors.green;
      case 'teacher': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'doctor': return Iconsax.hospital;
      case 'pharmacy': return Iconsax.receipt;
      case 'teacher': return Iconsax.teacher;
      default: return Iconsax.activity;
    }
  }

  String _getSubtypeLabel(String type, String subtype) {
    switch (type) {
      case 'doctor':
        return subtype == 'examination' ? 'كشف طبي' : 'استشارة طبية';
      case 'pharmacy':
        return 'طلب صيدلية';
      case 'teacher':
        return 'حجز معلم';
      default:
        return subtype;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredActivities();
    final l10n = AppLocalizations.of(context)!;
    final textColor = Colors.white;
    final secondaryColor = Colors.grey[400];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.myActivity,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.itemsFound(filteredList.length),
                        style: TextStyle(color: secondaryColor),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Sort Button
                  IconButton(
                    onPressed: () => setState(() => _sortNewest = !_sortNewest),
                    icon: Icon(
                      _sortNewest ? Iconsax.sort : Iconsax.sort,
                      color: textColor,
                    ),
                    tooltip: 'Sort by Date',
                  ),
                ],
              ),
            ),

            // Status Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildFilterChip(l10n.filterAll, 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip(l10n.filterCurrent, 'current'),
                  const SizedBox(width: 8),
                  _buildFilterChip(l10n.filterPast, 'past'),
                  const SizedBox(width: 8),
                  _buildFilterChip(l10n.filterAccepted, 'accepted'),
                  const SizedBox(width: 8),
                  _buildFilterChip(l10n.filterRejected, 'rejected'),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Type Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildTypeChip('الكل', 'all', Iconsax.category),
                  const SizedBox(width: 8),
                  _buildTypeChip('طبيب', 'doctor', Iconsax.hospital),
                  const SizedBox(width: 8),
                  _buildTypeChip('صيدلية', 'pharmacy', Iconsax.receipt),
                  const SizedBox(width: 8),
                  _buildTypeChip('معلم', 'teacher', Iconsax.teacher),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.box_1, size: 64, color: Colors.grey[600]),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noActivities,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final data = item['data'];
                            final type = item['type'];
                            
                            // Map user friendly values
                            String title = '';
                            String subtitle = '';
                            double? price;
                            
                            if (type == 'reservation') {
                              title = data['provider_name'] ?? 'Doctor/Teacher';
                              subtitle = data['provider_type'] == 'doctor' ? (data['specialty'] ?? 'Doctor') : (data['subject'] ?? 'Teacher');
                            } else {
                              title = data['pharmacy_name'] ?? 'Pharmacy';
                              subtitle = 'Order #${data['id']}';
                              price = data['total_price'] != null ? (data['total_price'] as num).toDouble() : null;
                            }

                            return UserActivityCard(
                              type: type,
                              title: title,
                              subtitle: subtitle,
                              date: item['date'],
                              status: item['status'],
                              price: price,
                              onTap: () => _showOrderDetails(item),
                              onAccept: () => _handleOrderAction(data['id'], 'accept'),
                              onReject: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(l10n.reject),
                                    content: const Text('Are you sure you want to cancel/reject this order?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(context, true), 
                                        style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                        child: Text(l10n.reject)
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) _handleOrderAction(data['id'], 'reject');
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, IconData icon) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _getTypeColor(value) : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _getTypeColor(value) : Colors.grey[600]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[800],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? Colors.white : Colors.grey[600]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black87 : Colors.grey[300],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
