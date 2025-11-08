import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/notification_item.dart';
import 'feedback_service.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(notification.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B124C), Color(0xFF5B2A9B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.imageUrl != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: notification.imageUrl!,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.white10,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.white10,
                        child: const Icon(Icons.error,
                            color: Colors.white54, size: 50),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                notification.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEEE, MMM d, yyyy - hh:mm a')
                    .format(notification.timestamp),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Divider(color: Colors.white24, height: 32),
              Text(
                notification.message,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 32),
              if (notification.route != null)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      FeedbackService.playSound(context);
                      FeedbackService.lightImpact(context);
                      context.push(notification.route!,
                          extra: notification.routeArgs);
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
