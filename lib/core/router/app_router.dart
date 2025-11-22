import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';

import '../models/movie.dart';
import '../models/cast.dart';
import '../models/review.dart';

import '../../providers/auth_provider.dart';

import '../../features/home/home_screen.dart';
import '../../features/home/see_all_screen.dart';
import '../../features/movie/movie_detail_screen.dart';
import '../../features/movie/see_all_reviews_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/favorites/my_list_see_all_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/notification_setting_screen.dart';
import '../../features/profile/my_reviews_screen.dart';
import '../../features/profile/security_screen.dart';
import '../../features/profile/change_password_screen.dart';
import '../../features/profile/help_center_screen.dart';
import '../../features/player/local_video_player_screen.dart';
import '../../features/player/youtube_player_screen.dart';
import '../../features/actor/actor_detail_screen.dart';
import '../../features/notifications/notification_list_screen.dart';
import '../../features/explore_news/explore_screen.dart';
import '../../features/explore_news/news_detail_screen.dart';

import '../../shared/widgets/main_wrapper.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/forgot_password_screen.dart';

import '../../features/home/coming_soon_screen.dart';

import 'page_transitions.dart';

class AppRouter {
  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorKey = GlobalKey<NavigatorState>();

  final AuthProvider authProvider;
  late final GoRouter router;

  AppRouter({required this.authProvider}) {
    router = GoRouter(
      initialLocation: '/',
      navigatorKey: _rootNavigatorKey,
      refreshListenable: authProvider, 
      redirect: (BuildContext context, GoRouterState state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final onAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password';

        if (!isLoggedIn && !onAuthRoute && state.matchedLocation != '/') {
          return '/login';
        }

        if (isLoggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
          return '/home';
        }

        return null; 
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/play-local/:id',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            final filePath = extra['filePath'] as String;
            final title = extra['title'] as String;
            return LocalVideoPlayerScreen(filePath: filePath, title: title);
          },
        ),
        GoRoute(
          path: '/play-youtube/:videoId',
          builder: (context, state) {
            final videoId = state.pathParameters['videoId']!;
            final extra = state.extra as Map<String, dynamic>?;
            final title = extra?['title'] as String? ?? 'Trailer';
            return YouTubePlayerScreen(videoId: videoId, title: title);
          },
        ),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return MainWrapper(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExploreScreen(),
            ),
            GoRoute(
              path: '/news-detail',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final articleUrl = extra['url'] as String? ?? '';
                final articleTitle = extra['title'] as String? ?? 'News Detail';
                return NewsDetailScreen(
                  articleUrl: articleUrl,
                  articleTitle: articleTitle,
                );
              },
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
              path: '/coming-soon',
              builder: (context, state) => const ComingSoonScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/movie/:id',
              pageBuilder: (context, state) {
                final movieId = int.parse(state.pathParameters['id']!);
                final extra = state.extra as Map<String, dynamic>?;
                final heroTag =
                    extra?['heroTag'] as String?; 
                final scrollToMyReview =
                    extra?['scrollToMyReview'] as bool? ?? false; 
                return PageTransitions.buildSharedAxisTransition(
                  context: context,
                  state: state,
                  transitionType:
                      SharedAxisTransitionType.scaled, 
                  child: MovieDetailScreen(
                    movieId: movieId,
                    heroTag: heroTag,
                    scrollToMyReview: scrollToMyReview,
                  ),
                );
              },
            ),
            GoRoute(
              path: '/tv/:id',
              pageBuilder: (context, state) {
                final tvShowId = int.parse(state.pathParameters['id']!);
                final extra = state.extra as Map<String, dynamic>?;
                final heroTag = extra?['heroTag'] as String?;
                final scrollToMyReview =
                    extra?['scrollToMyReview'] as bool? ?? false;
                return PageTransitions.buildSharedAxisTransition(
                  context: context,
                  state: state,
                  transitionType: SharedAxisTransitionType.scaled,
                  child: MovieDetailScreen(
                    movieId: tvShowId,
                    heroTag: heroTag,
                    scrollToMyReview: scrollToMyReview,
                    contentType: 'tv',
                  ),
                );
              },
            ),
            GoRoute(
              path: '/see-all-reviews',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final title = extra['title'] as String? ?? 'All Reviews';
                final reviews = extra['reviews'] as List<Review>? ?? [];
                return SeeAllReviewsScreen(title: title, reviews: reviews);
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
                final listType = extra['listType'] as MyListType;
                return MyListSeeAllScreen(
                  title: title,
                  listType: listType,
                );
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
              path: '/settings',
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
            GoRoute(
              path: '/change-password',
              builder: (context, state) => const ChangePasswordScreen(),
            ),
            GoRoute(
              path: '/profile/my-reviews',
              builder: (context, state) => const MyReviewsScreen(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationListScreen(),
            ),
          ],
        ), 
      ], 
    ); 
  }
}
