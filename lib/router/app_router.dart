import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/movie.dart';
import '../models/cast.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/shared/main_wrapper.dart';
import '../screens/movie/movie_detail_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/home/see_all_screen.dart';
import '../screens/favorites/my_list_see_all_screen.dart';
import '../screens/player/local_video_player_screen.dart';
import '../screens/actor/actor_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/notifications/notification_screen.dart';
import '../screens/shared/placeholder_screen.dart';
import '../screens/profile/help_center_screen.dart';
import '../screens/profile/security_screen.dart';

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
          return MainWrapper(child: child);
        },
        routes: [
          // ========== MAIN TABS ==========
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/my-list',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
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

          // ========== DETAIL SCREENS ==========
          GoRoute(
            path: '/movie/:id',
            builder: (context, state) {
              final movieId = int.parse(state.pathParameters['id']!);
              final extra = state.extra as Map<String, dynamic>?;
              final heroTag = extra?['heroTag'] as String?;
              return MovieDetailScreen(movieId: movieId, heroTag: heroTag);
            },
          ),
          GoRoute(
            path: '/see-all',
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
            path: '/play-local/:id',
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
            builder: (context, state) {
              final actorId = int.parse(state.pathParameters['id']!);
              return ActorDetailScreen(actorId: actorId);
            },
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationScreen(),
          ),
          GoRoute(
            path: '/help_center',
            builder: (context, state) => const HelpCenterScreen(),
          ),
          GoRoute(
            path: '/security',
            builder: (context, state) => const SecurityScreen(),
          ),
        ],
      ),
    ],
  );
}
