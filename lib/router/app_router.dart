import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/movie.dart';
import '../screens/favorites_screen.dart';
import '../models/notification_item.dart';
import '../screens/home_screen.dart';
import '../screens/main_wrapper.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/search_screen.dart';
import '../screens/see_all_screen.dart';
import '../screens/my_list_see_all_screen.dart'; // Import new screen
import '../screens/local_video_player_screen.dart'; // Import new screen
// Tạo file placeholder_screen.dart
import '../screens/actor_detail_screen.dart';
import '../screens/placeholder_screen.dart';
import '../screens/splash_screen.dart'; // Import SplashScreen
import '../models/cast.dart'; // Thêm import này
import '../screens/notifications_screen.dart'; // Import NotificationsScreen
import '../screens/notification_detail_screen.dart'; // Import NotificationDetailScreen
import 'package:provider/provider.dart'; // Import Provider package
import '../providers/settings_provider.dart'; // Import SettingsProvider

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/', // Đặt màn hình splash làm màn hình đầu tiên
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
            child: MainWrapper(child: child),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          // Đổi route /favorites thành /my-list
          GoRoute(
            path: '/my-list',
            builder: (context, state) =>
                const FavoritesScreen(), // Vẫn dùng FavoritesScreen
          ),
          // Thêm route /profile
          GoRoute(
            path: '/profile',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Profile'),
          ),
          GoRoute(
            path: '/sports',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Sports'),
          ),
          GoRoute(
            path: '/live',
            builder: (context, state) => const PlaceholderScreen(title: 'Live'),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notification-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final notification = state.extra as NotificationItem;
          return NotificationDetailScreen(notification: notification);
        },
      ),
      GoRoute(
        path: '/movie/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final movieId = int.parse(state.pathParameters['id']!);
          final extra = state.extra as Map<String, dynamic>?;
          final heroTag = extra?['heroTag'] as String?;
          return MovieDetailScreen(movieId: movieId, heroTag: heroTag);
        },
      ),
      GoRoute(
        path: '/see-all',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final title = extra['title'] as String? ?? 'All Movies';
          final movies = extra['movies'] as List<Movie>?;
          final castData = extra['cast'] as List<dynamic>?;
          return SeeAllScreen(
            title: title,
            movies: movies,
            cast: castData?.whereType<Cast>().toList(),
          );
        },
      ),
      GoRoute(
        path: '/my-list/see-all',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final title = extra['title'] as String? ?? 'All Items';
          final movies = extra['movies'] as List<Movie>? ?? [];
          final listType = extra['listType'] as MyListType;
          return MyListSeeAllScreen(
            title: title,
            movies: movies,
            listType: listType,
          );
        },
      ),
      GoRoute(
        path:
            '/play-local/:id', // Use movie ID for path, but pass filePath as extra
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final movieId = int.parse(state.pathParameters['id']!);
          final extra = state.extra as Map<String, dynamic>;
          final filePath = extra['filePath'] as String;
          final title = extra['title'] as String;
          return LocalVideoPlayerScreen(filePath: filePath, title: title);
        },
      ),
      GoRoute(
        path: '/actor/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final actorId = int.parse(state.pathParameters['id']!);
          return ActorDetailScreen(actorId: actorId);
        },
      ),
    ],
  );
}
