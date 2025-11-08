import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/main_wrapper.dart';
import '../screens/home_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/actor_detail_screen.dart';
import '../screens/my_list_see_all_screen.dart';
import '../screens/favorites_screen.dart';
import '../models/movie.dart';
import '../models/cast.dart'; // Import Cast model
import '../screens/local_player_screen.dart'; // Import màn hình player mới

// Placeholder screens for routes that don't have a file in the context
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title Screen',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  // Thêm một key cho ShellRoute
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/home', // Vẫn bắt đầu ở home
    navigatorKey: _rootNavigatorKey,
    routes: [
      // ShellRoute giờ đây sẽ bọc tất cả các route, bao gồm cả các trang chi tiết.
      // Route để phát video đã tải về, đặt ở đây để nó dùng _rootNavigatorKey
      // và hiển thị toàn màn hình.
      GoRoute(
        path: '/play-local/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final filePath = extra?['filePath'] as String?;
          final title = extra?['title'] as String?;

          if (filePath != null && title != null) {
            return LocalPlayerScreen(filePath: filePath, title: title);
          }
          return const Scaffold(
              body: Center(child: Text('Error: Missing file path or title.')));
        },
      ),

      ShellRoute(
        // Sử dụng shell navigator key để các trang con được đẩy vào bên trong ShellRoute
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainWrapper(child: child);
        },
        routes: [
          // Route cho tab Home
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => buildPageWithTransition<void>(
              context: context,
              state: state,
              child: const HomeScreen(),
            ),
          ),

          // Route cho tab Explore (Sports)
          GoRoute(
              path: '/sports',
              pageBuilder: (context, state) => buildPageWithTransition<void>(
                    context: context,
                    state: state,
                    child: const PlaceholderScreen(title: 'Explore'),
                  )),

          // Route cho tab Coming Soon (Live)
          GoRoute(
              path: '/live',
              pageBuilder: (context, state) => buildPageWithTransition<void>(
                    context: context,
                    state: state,
                    child: const PlaceholderScreen(title: 'Coming Soon'),
                  )),

          // Route cho tab My List
          GoRoute(
            path: '/my-list',
            pageBuilder: (context, state) => buildPageWithTransition<void>(
              context: context,
              state: state,
              child: const FavoritesScreen(),
            ),
            routes: [
              // Route con của My List
              GoRoute(
                path: 'see-all', // Đường dẫn tương đối: /my-list/see-all
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return MyListSeeAllScreen(
                    title: extra['title'] as String,
                    movies: extra['movies'] as List<Movie>,
                    listType: extra['listType'] as MyListType,
                  );
                },
              ),
            ],
          ),
          GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => buildPageWithTransition<void>(
                    context: context,
                    state: state,
                    child: const PlaceholderScreen(title: 'Profile'),
                  )),
          // CÁC ROUTE CHI TIẾT (TRANG CON) ĐƯỢC ĐẶT NGANG HÀNG VỚI CÁC TAB
          // Chúng vẫn là con của ShellRoute và sẽ hiển thị BottomNavBar.
          // Vì chúng là route cấp cao (bắt đầu bằng '/'), bạn có thể truy cập từ bất kỳ đâu.
          GoRoute(
            path: '/movie/:id', // Đường dẫn tuyệt đối
            parentNavigatorKey:
                _shellNavigatorKey, // Đảm bảo nó dùng navigator của ShellRoute
            builder: (context, state) {
              final movieId = int.parse(state.pathParameters['id']!);
              final extra = state.extra as Map<String, dynamic>?;
              return MovieDetailScreen(
                  movieId: movieId, heroTag: extra?['heroTag']);
            },
          ),
          GoRoute(
            path: '/actor/:id', // Đường dẫn tuyệt đối
            parentNavigatorKey:
                _shellNavigatorKey, // Đảm bảo nó dùng navigator của ShellRoute
            builder: (context, state) {
              final actorId = int.parse(state.pathParameters['id']!);
              final initialData =
                  state.extra as Cast?; // Nhận dữ liệu Cast ban đầu
              return ActorDetailScreen(
                  actorId: actorId, initialData: initialData);
            },
          ),
        ],
      ),
    ],
  );
}

/// Hàm helper để tạo CustomTransitionPage với hiệu ứng Fade.
/// Điều này giúp tránh lặp lại code.
CustomTransitionPage buildPageWithTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration:
        const Duration(milliseconds: 250), // Tùy chỉnh thời gian
  );
}
