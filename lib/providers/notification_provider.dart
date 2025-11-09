import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Import Uuid for unique IDs
import '../data/database_helper.dart';
import '../models/notification_item.dart';

class NotificationProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  List<NotificationItem> _notifications = [];
  final Map<String, NotificationItem> _tempRemoved = {}; // Lưu trữ tạm thời

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadNotifications();
  }

  // Tải thông báo từ SharedPreferences
  // Đã thay đổi để tải từ SQLite
  Future<void> _loadNotifications() async {
    _notifications = await _dbHelper.getNotifications();
    notifyListeners();
  }

  // Thêm một thông báo mới
  void addNotification({
    required String title,
    required String message,
    String? imageUrl,
    String? route,
    Map<String, dynamic>? routeArgs,
  }) {
    final newNotification = NotificationItem(
      id: _uuid.v4(), // Generate a unique ID
      title: title,
      message: message,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      route: route,
      routeArgs: routeArgs,
    );
    _dbHelper.addNotification(newNotification);
    _notifications.insert(0, newNotification); // Add to the beginning
    notifyListeners();
  }

  // Đánh dấu một thông báo là đã đọc
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _dbHelper.markNotificationAsRead(notificationId);
      notifyListeners();
    }
  }

  // Đánh dấu tất cả là đã đọc
  void markAllAsRead() {
    bool changed = false;
    for (var n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      _dbHelper.markAllNotificationsAsRead();
      notifyListeners();
    }
  }

  // Xóa tất cả thông báo
  void clearAllNotifications() {
    _notifications.clear();
    _dbHelper.deleteAllNotifications();
    notifyListeners();
  }

  // Tạm thời xóa một thông báo khỏi danh sách chính
  void removeNotificationTemporarily(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _tempRemoved[notificationId] = _notifications.removeAt(index);
      notifyListeners();
    }
  }

  // Chèn lại thông báo nếu người dùng hoàn tác
  void reinsertNotification(NotificationItem notification, int index) {
    // Không cần làm gì với DB ở đây, vì chúng ta chưa xóa nó
    _notifications.insert(index, notification);
    _tempRemoved.remove(notification.id);
    notifyListeners();
  }

  // Xóa vĩnh viễn thông báo khỏi SQLite
  void confirmRemoveNotification(String notificationId) {
    _tempRemoved.remove(notificationId);
    _dbHelper.deleteNotification(notificationId);
  }
}
