import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_glow/flutter_glow.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_item.dart';
import '../api/api_constants.dart';
import '../providers/movie_provider.dart'; // Import MovieProvider
import '../models/movie.dart'; // Import Movie model
import 'feedback_service.dart'; // Import service mới

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () {
                  FeedbackService.playSound(context);
                  FeedbackService.lightImpact(context);
                  provider.markAllAsRead();
                },
                child: const Text(
                  'Mark All Read',
                  style: TextStyle(color: Colors.pinkAccent),
                ),
              );
            },
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined,
                    color: Colors.white70),
                onPressed: () {
                  FeedbackService.playSound(context);
                  FeedbackService.lightImpact(context);
                  _showClearAllDialog(context, provider);
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B124C), Color(0xFF5B2A9B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            if (provider.notifications.isEmpty) {
              // Hiển thị gợi ý phim khi không có thông báo
              return _buildEmptyStateWithSuggestion(context);
            }
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: provider.notifications.length,
                itemBuilder: (context, index) {
                  final notification = provider.notifications[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildNotificationTile(
                            context, notification, provider, index),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context,
      NotificationItem notification, NotificationProvider provider, int index) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // Tạm thời xóa khỏi provider để UI cập nhật
        provider.removeNotificationTemporarily(notification.id);

        // Hiển thị SnackBar với nút "Hoàn tác"
        ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
                content: Text('Đã xóa: ${notification.title}'),
                action: SnackBarAction(
                  label: 'Hoàn tác',
                  onPressed: () {
                    // Nếu người dùng hoàn tác, chèn lại item
                    provider.reinsertNotification(notification, index);
                  },
                ),
              ),
            )
            .closed
            .then((reason) {
          // Nếu SnackBar đóng mà không phải do nhấn "Hoàn tác", thì mới xóa vĩnh viễn
          if (reason != SnackBarClosedReason.action) {
            provider.confirmRemoveNotification(notification.id);
          }
        });
      },
      background: Container(
        color: Colors.red.withOpacity(0.8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Card(
        color: notification.isRead
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.15),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: notification.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl:
                        '${ApiConstants.imageBaseUrl}${notification.imageUrl}',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                )
              : Icon(Icons.info_outline,
                  color: Colors.pinkAccent.withOpacity(0.8)),
          title: Text(
            notification.title,
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d, yyyy - hh:mm a')
                    .format(notification.timestamp),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          trailing: notification.isRead ? null : _buildGlowPulse(),
          onTap: () {
            FeedbackService.playSound(context);
            FeedbackService.lightImpact(context);
            provider.markAsRead(notification.id);
            context.push('/notification-detail', extra: notification);
          },
        ),
      ),
    );
  }

  Widget _buildGlowPulse() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final size = 10 + (_pulseController.value * 4);
        return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                color:
                    Colors.blueAccent.withOpacity(1 - _pulseController.value),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.7),
                    blurRadius: 8,
                    spreadRadius: _pulseController.value * 2,
                  )
                ]));
      },
    );
  }

  void _showClearAllDialog(
      BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A0CA3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Clear All Notifications?'),
          content: const Text(
              'Are you sure you want to remove all notifications? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child:
                  const Text('Clear All', style: TextStyle(color: Colors.red)),
              onPressed: () {
                FeedbackService.playSound(context);
                FeedbackService.lightImpact(context);
                provider.clearAllNotifications();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Widget mới: Hiển thị trạng thái trống với gợi ý phim
  Widget _buildEmptyStateWithSuggestion(BuildContext context) {
    // Lấy danh sách phim từ MovieProvider
    final movieProvider = context.watch<MovieProvider>();
    final suggestionMovies = movieProvider.popularMovies;

    // Chọn một phim ngẫu nhiên nếu danh sách không rỗng
    Movie? suggestedMovie;
    if (suggestionMovies.isNotEmpty) {
      suggestedMovie = (suggestionMovies..shuffle()).first;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 80, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Your inbox is empty',
              style:
                  TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              'New updates and recommendations will appear here.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
            ),
            const SizedBox(height: 40),

            // Hiển thị thẻ gợi ý phim nếu có
            if (suggestedMovie != null)
              _buildMovieSuggestionCard(context, suggestedMovie),
          ],
        ),
      ),
    );
  }

  // Widget mới: Thẻ gợi ý phim
  Widget _buildMovieSuggestionCard(BuildContext context, Movie movie) {
    return GestureDetector(
      onTap: () {
        FeedbackService.playSound(context);
        FeedbackService.lightImpact(context);
        context.push('/movie/${movie.id}');
      },
      child: GlowContainer(
        glowColor: Colors.pinkAccent.withOpacity(0.5),
        blurRadius: 15,
        spreadRadius: 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: '${ApiConstants.imageBaseUrl}${movie.posterPath}',
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FOR YOU',
                      style: TextStyle(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.overview,
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
