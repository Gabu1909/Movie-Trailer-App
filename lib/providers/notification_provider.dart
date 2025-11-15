import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';
import '../models/cast.dart';
import '../models/movie.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  static const _notificationsKey = 'app_notifications';
  static const _maxNotifications = 50; // Giới hạn số lượng thông báo

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsString = prefs.getString(_notificationsKey);
    if (notificationsString != null) {
      final List<dynamic> decodedList = json.decode(notificationsString);
      _notifications = decodedList.map((item) => AppNotification.fromJson(item)).toList();
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sắp xếp mới nhất lên đầu

      // Áp dụng giới hạn khi tải
      if (_notifications.length > _maxNotifications) {
        _notifications = _notifications.sublist(0, _maxNotifications);
      }

      notifyListeners();
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(_notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_notificationsKey, encodedList);
  }

  void addNotification(AppNotification notification) {
    // Tránh thêm thông báo trùng lặp (ví dụ: coming soon)
    if (_notifications.any((n) => n.id == notification.id)) return;

    _notifications.insert(0, notification);

    // Nếu danh sách vượt quá giới hạn, hãy xóa thông báo cũ nhất
    if (_notifications.length > _maxNotifications) {
      _notifications.removeLast();
    }

    _saveNotifications();
    notifyListeners();
  }

  void addComingSoonNotifications(List<Movie> upcomingMovies) {
    for (var movie in upcomingMovies) {
      final notification = AppNotification(
        id: 'coming_soon_${movie.id}',
        title: 'Sắp ra mắt!',
        body: 'Đừng bỏ lỡ bộ phim "${movie.title}" sắp được công chiếu.',
        timestamp: DateTime.now(),
        type: NotificationType.comingSoon,
        movieId: movie.id,
      );
      addNotification(notification);
    }
  }

  void addTrendingNotifications(List<Movie> trendingMovies) {
    // Chỉ lấy 3 phim hot nhất để làm thông báo
    final topTrending = trendingMovies.take(3).toList();
    for (var movie in topTrending) {
      final notification = AppNotification(
        id: 'trending_week_${movie.id}',
        title: '🔥 Hot nhất tuần!',
        body: 'Đừng bỏ lỡ siêu phẩm "${movie.title}" đang thịnh hành.',
        timestamp: DateTime.now(),
        type: NotificationType.trending,
        movieId: movie.id,
      );
      addNotification(notification);
    }
  }

  void addNowPlayingNotifications(List<Movie> nowPlayingMovies) {
    // Lấy 3 phim mới nhất
    final latest = nowPlayingMovies.take(3).toList();
    for (var movie in latest) {
      final notification = AppNotification(
        id: 'now_playing_${movie.id}',
        title: '🎥 Mới phát hành!',
        body: 'Thưởng thức ngay bộ phim "${movie.title}" vừa ra mắt.',
        timestamp: DateTime.now(),
        type: NotificationType.nowPlaying,
        movieId: movie.id,
      );
      addNotification(notification);
    }
  }

  void addActorInNewMovieNotification(Cast actor, Movie movie) {
    final notification = AppNotification(
      id: 'actor_${actor.id}_movie_${movie.id}',
      title: '🎭 Ngôi sao tái xuất!',
      body:
          '${actor.name} vừa góp mặt trong siêu phẩm "${movie.title}". Khám phá ngay!',
      timestamp: DateTime.now(),
      type: NotificationType.actor,
      // Cho phép nhấn vào thông báo để xem chi tiết phim
      movieId: movie.id,
    );
    addNotification(notification);
  }

  // Hàm này có thể được gọi từ bất cứ đâu để tạo thông báo hệ thống
  void addSystemNotification({required String id, required String title, required String body}) {
    final notification = AppNotification(
        id: id, title: title, body: body, timestamp: DateTime.now(), type: NotificationType.system);
    addNotification(notification);
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _saveNotifications();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool hasChanged = false;
    for (var notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        hasChanged = true;
      }
    }
    if (hasChanged) {
      _saveNotifications();
      notifyListeners();
    }
  }

  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _saveNotifications();
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }
}