import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final res = await _api.getNotifications(limit: 50);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.isSuccess) {
          _notifications = res.data ?? [];
        }
      });
    }
  }
  
  Future<void> _markAsRead(int id) async {
    await _api.markNotificationRead(id);
    // Locally update UI
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['is_read'] = true;
      }
    });
  }
  
  Future<void> _markAllRead() async {
    await _api.markAllNotificationsRead();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("التنبيهات"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton.icon(
              onPressed: _markAllRead, 
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text("قراءة الكل"),
            )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.notification, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("لا يوجد تنبيهات جديدة", style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    final isRead = item['is_read'] == true;
                    final date = DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now();
                    
                    return Dismissible(
                      key: Key(item['id'].toString()),
                       background: Container(color: Colors.red),
                       onDismissed: (direction) {
                          // Ideally implement delete, for now just hide
                       },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isRead ? Colors.grey[200]! : AppColors.primary.withOpacity(0.3)),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (!isRead) _markAsRead(item['id']);
                            // Handle navigation based on data['type'] if needed
                          },
                          leading: CircleAvatar(
                            backgroundColor: isRead ? Colors.grey[100] : AppColors.primary.withOpacity(0.1),
                            child: Icon(
                              Iconsax.notification, 
                              color: isRead ? Colors.grey : AppColors.primary,
                              size: 20
                            ),
                          ),
                          title: Text(
                            item['title'],
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(item['body']),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('dd/MM/yyyy hh:mm a').format(date),
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                          trailing: !isRead 
                              ? Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))
                              : null,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
