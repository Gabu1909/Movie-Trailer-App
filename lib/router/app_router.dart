// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/movie.dart';
import '../screens/about_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_wrapper.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/search_screen.dart';
import '../screens/see_all_screen.dart';
import '../screens/settings_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    navigatorKey: _rootNavigatorKey,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainWrapper(child: child); // Wrapper with BottomNavBar
        },
        routes: [
          // Đưa Search trở lại đây
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/movie/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final movieId = int.parse(state.pathParameters['id']!);
          return MovieDetailScreen(movieId: movieId);
        },
      ),
      GoRoute(
        path: '/see-all',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final title = extra['title'] as String? ?? 'All Movies';
          final movies = extra['movies'] as List<Movie>? ?? [];
          return SeeAllScreen(title: title, movies: movies);
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
}
