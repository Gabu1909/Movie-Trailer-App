import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/favorites_provider.dart'; // Import FavoritesProvider
import 'providers/movie_provider.dart'; // Import MovieProvider
import 'providers/downloads_provider.dart'; // Import DownloadsProvider
import 'providers/notification_provider.dart'; // Import NotificationProvider
import 'providers/watchlist_provider.dart'; // Import WatchlistProvider
import 'providers/bottom_nav_visibility_provider.dart'; // Import BottomNavVisibilityProvider
import 'providers/settings_provider.dart'; // Import SettingsProvider
import 'providers/movie_detail_provider.dart'; // Import MovieDetailProvider
import 'providers/actor_detail_provider.dart'; // Import ActorDetailProvider
import 'providers/auth_provider.dart'; // Import AuthProvider
import 'providers/search_provider.dart'; // Import SearchProvider
import 'providers/my_reviews_provider.dart'; // Import MyReviewsProvider
import 'router/app_router.dart'; // Import AppRouter
import 'api/api_service.dart'; // Import ApiService
import 'services/local_notification_service.dart'; // Import LocalNotificationService
import 'theme/constants.dart'; // Import theme constants
import 'theme/custom_colors.dart'; // Import CustomColors
import 'theme/app_themes.dart'; // Import các theme mới

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Đảm bảo Flutter binding được khởi tạo
  await LocalNotificationService.initialize(); // Khởi tạo dịch vụ thông báo
  runApp(const MyApp()); // Chạy ứng dụng
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Các provider không phụ thuộc
        ChangeNotifierProvider(create: (_) => MovieProvider(ApiService())),

        // FavoritesProvider phụ thuộc vào AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (context) => FavoritesProvider(),
          update: (context, authProvider, previous) {
            final provider = previous ?? FavoritesProvider();
            provider.setUserId(authProvider.currentUser?.id);
            return provider;
          },
        ),

        // WatchlistProvider phụ thuộc vào AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, WatchlistProvider>(
          create: (context) => WatchlistProvider(),
          update: (context, authProvider, previous) {
            final provider = previous ?? WatchlistProvider();
            provider.setUserId(authProvider.currentUser?.id);
            return provider;
          },
        ),

        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => BottomNavVisibilityProvider()),
        ChangeNotifierProvider(create: (_) => ActorDetailProvider()),
        ChangeNotifierProvider(create: (_) => MovieDetailProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(
            create: (_) => MyReviewsProvider()), // Thêm MyReviewsProvider
        ChangeNotifierProvider(
            create: (_) => SearchProvider()), // Thêm SearchProvider
        // DownloadsProvider phụ thuộc vào NotificationProvider và AuthProvider
        ChangeNotifierProxyProvider2<NotificationProvider, AuthProvider,
            DownloadsProvider>(
          create: (context) => DownloadsProvider(
              notificationProvider: context.read<NotificationProvider>()),
          update: (context, notificationProvider, authProvider, previous) {
            final provider = previous ??
                DownloadsProvider(notificationProvider: notificationProvider);
            provider.updateDependencies(notificationProvider);
            provider.setUserId(authProvider.currentUser?.id);
            return provider;
          },
        ),
      ],
      child: Builder(builder: (context) {
        // Lấy AuthProvider và SettingsProvider
        final authProvider = Provider.of<AuthProvider>(context);
        final settingsProvider = Provider.of<SettingsProvider>(context);
        // Tạo AppRouter và truyền AuthProvider vào
        final appRouter = AppRouter(authProvider: authProvider);
        // Lấy theme được chọn từ provider
        final selectedTheme = AppThemes.findById(settingsProvider.themeId);

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Movie App',
          // Luôn sử dụng theme tối và chỉ thay đổi dữ liệu của nó
          themeAnimationDuration: const Duration(milliseconds: 500), // Thời gian chuyển đổi
          themeAnimationCurve: Curves.easeInOut, // Kiểu chuyển đổi
          themeMode: ThemeMode.dark,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: selectedTheme.scaffoldColor,
            primaryColor: selectedTheme.primaryColor,
            colorScheme: ColorScheme.dark(
              primary: selectedTheme.primaryColor,
              secondary: selectedTheme.primaryColor.withOpacity(0.7),
              surface: selectedTheme.surfaceColor,
              background: selectedTheme.scaffoldColor,
              onSurface: Colors.white,
              onBackground: Colors.white,
            ),
            textTheme: const TextTheme(
              headlineSmall: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24),
              titleLarge: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
              titleMedium: TextStyle(color: Colors.white, fontSize: 16),
              bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
              bodySmall: TextStyle(color: Colors.white60, fontSize: 12),
              labelLarge: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: selectedTheme.surfaceColor,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: selectedTheme.primaryColor,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              unselectedLabelStyle:
                  const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            cardTheme: CardThemeData(
              color: selectedTheme.surfaceColor,
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: selectedTheme.surfaceColor.withOpacity(0.8),
              disabledColor: selectedTheme.surfaceColor,
              selectedColor: selectedTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              labelStyle: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold),
              secondaryLabelStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.transparent),
              ),
            ),
            // Thêm extension màu tùy chỉnh cho Dark Theme
            extensions: <ThemeExtension<dynamic>>[
              CustomColors(
                  success: Colors.greenAccent[400],
                  warning: Colors.orangeAccent[400],
                  info: Colors.lightBlueAccent[400],
                  shimmerBase: Colors.grey[850]!,
                  shimmerHighlight: Colors.grey[800]!,
                  subtitleStyle: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
          darkTheme: null, // Không cần darkTheme riêng nữa
          routerConfig: appRouter.router,
        );
      }),
    );
  }
}
