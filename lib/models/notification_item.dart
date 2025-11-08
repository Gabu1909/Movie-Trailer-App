class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String? imageUrl; // Optional image for notification
  final String? route; // Optional route to navigate to when tapped
  final Map<String, dynamic>? routeArgs; // Optional arguments for the route

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.route,
    this.routeArgs,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'imageUrl': imageUrl,
      'route': route,
      'routeArgs': routeArgs,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] == 1,
      imageUrl: map['imageUrl'],
      route: map['route'],
      routeArgs: map['routeArgs'] != null ? Map<String, dynamic>.from(map['routeArgs']) : null,
    );
  }
}