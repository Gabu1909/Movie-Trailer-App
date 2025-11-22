import 'package:flutter/material.dart';
import '../../core/models/app_notification.dart';
import '../../core/models/cast.dart';
import '../../core/models/review.dart';
import '../../core/models/movie.dart';
import '../../core/data/database_helper.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  static const _maxNotifications = 50;
  String? _currentUserId;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
  }

  Future<void> setUserId(String? userId) async {
    print('NotificationProvider.setUserId called');
    print('Previous userId: $_currentUserId');
    print('New userId: $userId');
    
    if (_currentUserId != userId) {
      _currentUserId = userId;
      print('UserId changed, loading notifications...');
      await _loadNotifications();
    } else {
      print('UserId unchanged, skipping reload');
    }
  }

  Future<void> _loadNotifications() async {
    if (_currentUserId == null) {
      _notifications = [];
      notifyListeners();
      return;
    }

    try {
      final notificationMaps = await DatabaseHelper.instance.getNotifications(_currentUserId!);
      print('📱 Loading ${notificationMaps.length} notifications for user $_currentUserId');
      
      _notifications = notificationMaps.map((map) {
        final route = map['route'] as String?;
        final typeString = route?.split('_').last ?? 'system';
        
        NotificationType notifType = NotificationType.system;
        try {
          notifType = NotificationType.values.firstWhere(
            (e) => e.toString().toLowerCase() == 'notificationtype.$typeString'.toLowerCase(),
          );
        } catch (e) {
          print('Could not parse notification type: $typeString, defaulting to system');
        }
        
        final notification = AppNotification(
          id: map['id'] as String,
          title: map['title'] as String,
          body: map['message'] as String,
          timestamp: DateTime.parse(map['timestamp'] as String),
          isRead: (map['isRead'] as int) == 1,
          type: notifType,
          movieId: map['routeArgs'] != null ? int.tryParse(map['routeArgs'] as String) : null,
        );
        
        print('Loaded notification: ${notification.title} - Type: ${notification.type}');
        return notification;
      }).toList();

      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (_notifications.length > _maxNotifications) {
        _notifications = _notifications.sublist(0, _maxNotifications);
      }

      print('Successfully loaded ${_notifications.length} notifications');
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error loading notifications: $e');
      print('Stack trace: $stackTrace');
      _notifications = [];
      notifyListeners();
    }
  }

  Future<void> _saveNotification(AppNotification notification) async {
    if (_currentUserId == null) {
      print('⚠️ Cannot save notification: _currentUserId is null');
      return;
    }

    print('💾 Saving notification to database:');
    print('   UserId: $_currentUserId');
    print('   Title: ${notification.title}');
    print('   ID: ${notification.id}');

    await DatabaseHelper.instance.saveNotification({
      'id': notification.id,
      'userId': _currentUserId!,
      'title': notification.title,
      'message': notification.body,
      'timestamp': notification.timestamp.toIso8601String(),
      'isRead': notification.isRead ? 1 : 0,
      'imageUrl': null,
      'route': 'notification_${notification.type.toString().split('.').last}',
      'routeArgs': notification.movieId?.toString(),
    });
    
    print('✅ Notification saved successfully');
  }

  Future<void> addNotification(AppNotification notification) async {
    if (_notifications.any((n) => n.id == notification.id)) return;

    _notifications.insert(0, notification);

    if (_notifications.length > _maxNotifications) {
      _notifications.removeLast();
    }

    await _saveNotification(notification);
    notifyListeners();
  }

  Future<void> addNotificationForUser(String userId, AppNotification notification) async {
    print('Saving notification for user: $userId');
    print('Title: ${notification.title}');
    print('Body: ${notification.body}');
    print('MovieId: ${notification.movieId}');
    
    await DatabaseHelper.instance.saveNotification({
      'id': notification.id,
      'userId': userId,
      'title': notification.title,
      'message': notification.body,
      'timestamp': notification.timestamp.toIso8601String(),
      'isRead': 0,
      'imageUrl': null,
      'route': 'notification_${notification.type.toString().split('.').last}',
      'routeArgs': notification.movieId?.toString(),
    });
    
    print('Notification saved to database for user: $userId');

    if (userId == _currentUserId) {
      print('User is currently logged in, adding to in-memory list');
      _notifications.insert(0, notification);
      if (_notifications.length > _maxNotifications) {
        _notifications.removeLast();
      }
      notifyListeners();
    } else {
      print('User $userId will see notification when they log in');
    }
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
    final topTrending = trendingMovies.take(3).toList();
    for (var movie in topTrending) {
      final notification = AppNotification(
        id: 'trending_week_${movie.id}',
        title: 'Hot nhất tuần!',
        body: 'Đừng bỏ lỡ siêu phẩm "${movie.title}" đang thịnh hành.',
        timestamp: DateTime.now(),
        type: NotificationType.trending,
        movieId: movie.id,
      );
      addNotification(notification);
    }
  }

  void addNowPlayingNotifications(List<Movie> nowPlayingMovies) {
    final latest = nowPlayingMovies.take(3).toList();
    for (var movie in latest) {
      final notification = AppNotification(
        id: 'now_playing_${movie.id}',
        title: 'Mới phát hành!',
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
      title: 'Ngôi sao tái xuất!',
      body:
          '${actor.name} vừa góp mặt trong siêu phẩm "${movie.title}". Khám phá ngay!',
      timestamp: DateTime.now(),
      type: NotificationType.actor,
      movieId: movie.id,
    );
    addNotification(notification);
  }

  void addSystemNotification(
      {required String id, required String title, required String body}) {
    final notification = AppNotification(
        id: id,
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: NotificationType.system);
    addNotification(notification);
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      await DatabaseHelper.instance.markNotificationAsRead(notificationId);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    bool hasChanged = false;
    for (var notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        await DatabaseHelper.instance.markNotificationAsRead(notification.id);
        hasChanged = true;
      }
    }
    if (hasChanged) {
      notifyListeners();
    }
  }

  Future<void> removeNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    if (_currentUserId != null) {
      await DatabaseHelper.instance.clearNotifications(_currentUserId!);
      _notifications.clear();
      notifyListeners();
    }
  }
}
