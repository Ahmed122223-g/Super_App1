import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiwar_web/core/providers/current_user_provider.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class UserProfileTab extends ConsumerStatefulWidget {
  const UserProfileTab({super.key});

  @override
  ConsumerState<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends ConsumerState<UserProfileTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();

  bool _isLoadingReservations = true;
  bool _isLoadingOrders = true;
  List<dynamic> _reservations = [];
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadReservations();
    _loadOrders();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoadingReservations = true);
    final response = await _api.getMyReservations();
    if (mounted) {
      setState(() {
        _isLoadingReservations = false;
        if (response.isSuccess) {
          _reservations = response.data ?? [];
        }
      });
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoadingOrders = true);
    final response = await _api.getMyOrders();
    if (mounted) {
      setState(() {
        _isLoadingOrders = false;
        if (response.isSuccess) {
          _orders = response.data ?? [];
        }
      });
    }
  }

  Future<void> _cancelReservation(int id, String providerType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الحجز'),
        content: const Text('هل أنت متأكد من إلغاء هذا الحجز؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _api.cancelReservation(id, providerType);
      if (mounted) {
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إلغاء الحجز'), backgroundColor: Colors.green),
          );
          _loadReservations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.errorMessage ?? 'حدث خطأ'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Icon(Iconsax.user, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      user != null ? (user['name'] ?? 'Guest User') : 'Loading...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Email/Info
                    Text(
                      user != null ? (user['email'] ?? '') : '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    if (user != null && user['phone'] != null)
                      Text(
                        user['phone'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                color: cardColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  tabs: const [
                    Tab(text: "حجوزاتي", icon: Icon(Iconsax.calendar)),
                    Tab(text: "طلباتي", icon: Icon(Iconsax.bag_2)),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReservationsTab(),
                _buildOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsTab() {
    if (_isLoadingReservations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reservations.isEmpty) {
      return _buildEmptyState("لا توجد حجوزات حالياً", Iconsax.calendar_remove);
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reservations.length,
        itemBuilder: (context, index) {
          final item = _reservations[index];
          return _buildReservationCard(item);
        },
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return _buildEmptyState("لا توجد طلبات حالياً", Iconsax.bag_cross);
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final item = _orders[index];
          return _buildOrderCard(item);
        },
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> item) {
    final providerType = item['provider_type'] ?? 'doctor';
    final providerName = item['provider_name'] ?? 'Unknown';
    final specialty = item['specialty'] ?? item['subject'] ?? '';
    final status = item['status'] ?? 'pending';
    final visitDate = item['visit_date'] != null 
        ? DateTime.parse(item['visit_date']) 
        : DateTime.now();

    Color statusColor;
    String statusText;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusText = 'مؤكد';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'مكتمل';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusText = 'ملغي';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'مرفوض';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (providerType == 'doctor' ? Colors.blue : Colors.purple).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    providerType == 'doctor' ? Iconsax.health : Iconsax.teacher,
                    color: providerType == 'doctor' ? Colors.blue : Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Iconsax.calendar_1, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'ar').format(visitDate),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const Spacer(),
                // Cancel Button (only for pending)
                if (status == 'pending')
                  InkWell(
                    onTap: () => _cancelReservation(item['id'], providerType),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.close_circle, color: Colors.red, size: 18),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> item) {
    final pharmacyName = item['pharmacy_name'] ?? 'Unknown';
    final status = item['status'] ?? 'pending';
    final createdAt = item['created_at'] != null 
        ? DateTime.parse(item['created_at']) 
        : DateTime.now();
    final totalPrice = item['total_price'];
    final itemsText = item['items_text'] ?? 'طلب بالروشتة';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'priced':
        statusColor = Colors.blue;
        statusText = 'تم التسعير';
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'مقبول';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusText = 'تم التوصيل';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'مرفوض';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusText = 'ملغي';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.hospital, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacyName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        itemsText.length > 50 ? '${itemsText.substring(0, 50)}...' : itemsText,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Iconsax.calendar_1, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('d MMMM yyyy', 'ar').format(createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const Spacer(),
                if (totalPrice != null)
                  Text(
                    '${totalPrice.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('تحديث'),
          ),
        ],
      ),
    );
  }
}
