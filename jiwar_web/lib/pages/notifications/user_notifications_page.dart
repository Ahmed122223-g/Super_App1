import 'package:flutter/material.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class UserNotificationsPage extends StatefulWidget {
  const UserNotificationsPage({super.key});

  @override
  State<UserNotificationsPage> createState() => _UserNotificationsPageState();
}

class _UserNotificationsPageState extends State<UserNotificationsPage> {
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
    final response = await _api.getNotifications(limit: 50);
    
    if (response.isSuccess) {
      if (mounted) {
        setState(() {
          _notifications = response.data ?? [];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: ${response.errorMessage}'))
        );
      }
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    // Optimistic update
    setState(() {
      _notifications[index]['is_read'] = true;
    });

    final response = await _api.markNotificationRead(id);
    if (!response.isSuccess) {
      // Revert if failed
      if (mounted) {
        setState(() {
          _notifications[index]['is_read'] = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    final response = await _api.markAllNotificationsRead();
    if (response.isSuccess) {
       _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('التنبيهات'),
        backgroundColor: AppColors.surfaceDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'تحديد الكل كمقروء',
            onPressed: _markAllRead,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد تنبيهات حالياً',
                        style: TextStyle(color: Colors.grey[500], fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isRead = notif['is_read'] == true;
                    final date = DateTime.parse(notif['created_at']);
                    
                    return Dismissible(
                      key: Key(notif['id'].toString()),
                      background: Container(color: Colors.red),
                      onDismissed: (_) {
                        // Ideally add delete endpoint, but for now just hide
                        setState(() {
                          _notifications.removeAt(index);
                        });
                      },
                      child: Card(
                        color: isRead ? AppColors.surfaceDark : AppColors.surfaceDark.withOpacity(0.8),
                        elevation: isRead ? 1 : 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isRead ? BorderSide.none : const BorderSide(color: AppColors.primary, width: 1),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (!isRead) _markAsRead(notif['id'], index);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isRead ? Colors.grey[800] : AppColors.primary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isRead ? Icons.notifications_none : Icons.notifications_active,
                                    color: isRead ? Colors.grey[400] : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif['title'] ?? 'Title',
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['body'] ?? 'Body',
                                        style: TextStyle(color: Colors.grey[300]),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        timeago.format(date, locale: 'en'), // You can add 'ar' locale support
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
