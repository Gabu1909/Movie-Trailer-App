// (Code của app_router.dart đã được gửi)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/about_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_wrapper.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';

class AppRouter {
  // Key cho Navigator chính (Root)
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  // Key cho Navigator của ShellRoute (chứa BottomNavBar)
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    navigatorKey: _rootNavigatorKey,
    routes: [
      // 1. ShellRoute cho các màn hình có BottomNavigationBar
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainWrapper(
              child: child); // Bọc màn hình con trong MainWrapper
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _buildPageWithTransition(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => _buildPageWithTransition(
              key: state.pageKey,
              child: const SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) => _buildPageWithTransition(
              key: state.pageKey,
              child: const FavoritesScreen(),
            ),
          ),
        ],
      ),
      // 2. Các Routes không có BottomNavigationBar (điều hướng từ Root)
      GoRoute(
        path: '/movie/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          // Lấy ID phim từ URL
          final movieId = int.parse(state.pathParameters['id']!);
          return MovieDetailScreen(movieId: movieId);
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );

  // Phương thức tạo CustomTransitionPage cho hiệu ứng chuyển màn hình
  static Page _buildPageWithTransition(
      {required LocalKey key, required Widget child}) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Ví dụ: Hiệu ứng Fade Transition
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}
