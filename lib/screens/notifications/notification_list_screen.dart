import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final allNotifications = provider.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFF12002F),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF1F0445).withOpacity(0.8),
        elevation: 0,
        actions: [
          if (allNotifications.isNotEmpty) // Chỉ hiển thị menu nếu có thông báo
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  provider.markAllAsRead();
                } else if (value == 'clear_all') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm'),
                      content: const Text(
                          'Are you sure you want to clear all notifications? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        TextButton(
                          child: const Text('Clear',
                              style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            provider.clearAllNotifications();
                          },
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                if (provider.unreadCount > 0)
                  const PopupMenuItem<String>(
                    value: 'mark_all_read',
                    child: Text('Mark all as read'),
                  ),
                const PopupMenuItem<String>(
                  value: 'clear_all',
                  child: Text('Clear all notifications'),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),
      body: _buildNotificationList(
          context, allNotifications, 'You have no notifications.'),
    );
  }

  // Widget để xây dựng danh sách thông báo, có thể tái sử dụng
  Widget _buildNotificationItem(BuildContext context, AppNotification notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.download:
        iconData = Icons.download_done;
        iconColor = Colors.green;
        break;
      case NotificationType.comingSoon:
        iconData = Icons.new_releases;
        iconColor = Colors.orange;
        break;
      case NotificationType.trending:
        iconData = Icons.local_fire_department;
        iconColor = Colors.redAccent;
        break;
      case NotificationType.nowPlaying:
        iconData = Icons.theaters;
        iconColor = Colors.lightBlueAccent;
        break;
      case NotificationType.system:
        iconData = Icons.info;
        iconColor = Colors.purpleAccent;
        break;
      case NotificationType.actor:
        iconData = Icons.star_border_purple500_outlined;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.blue;
    }

    return Dismissible(
      key: Key(notification.id), // Key là bắt buộc để Flutter xác định đúng widget
      direction: DismissDirection.endToStart, // Chỉ cho phép vuốt từ phải sang trái
      onDismissed: (direction) {
        // Gọi provider để xóa thông báo khỏi danh sách
        context.read<NotificationProvider>().removeNotification(notification.id);

        // Hiển thị SnackBar để thông báo và có thể hoàn tác
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${notification.title}" đã được xóa.')),
        );
      },
      background: Container(
        color: Colors.red.withOpacity(0.8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: () {
          context.read<NotificationProvider>().markAsRead(notification.id);
          if (notification.movieId != null) {
            context.push('/movie/${notification.movieId}');
          }
        },
        child: Container(
          color: notification.isRead ? Colors.transparent : Colors.white.withOpacity(0.05),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconData, color: iconColor, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(notification.body, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(timeago.format(notification.timestamp), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget để hiển thị ListView hoặc thông báo trống
  Widget _buildNotificationList(BuildContext context, List<AppNotification> notifications, String emptyMessage) {
    if (notifications.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(context, notification);
      },
    );
  }
}