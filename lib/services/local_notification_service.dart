import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Cài đặt cho Android
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings(
            'notification_icon'); // Sử dụng icon mới, đúng chuẩn

    // Cài đặt cho iOS
    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'movie_app_channel', // ID của channel
        'Movie App Notifications', // Tên của channel
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }
}
