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
import 'router/app_router.dart'; // Import AppRouter
import 'services/local_notification_service.dart'; // Import LocalNotificationService
import 'theme/constants.dart'; // Import theme constants

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
        ChangeNotifierProvider(create: (_) => MovieProvider()),

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
        // Lấy AuthProvider đã được khởi tạo
        final authProvider = Provider.of<AuthProvider>(context);
        // Tạo AppRouter và truyền AuthProvider vào
        final appRouter = AppRouter(authProvider: authProvider);

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Movie App',
          theme: ThemeData(
            brightness: Brightness.dark,
            // Nền sẽ được set bằng Gradient trong home_screen,
            // nhưng scaffoldBackgroundColor vẫn cần thiết
            scaffoldBackgroundColor: kDarkPurpleColor,
            primaryColor: kPrimaryColor,

            colorScheme: const ColorScheme.dark(
              primary: kPrimaryColor,
              secondary: kPrimaryColorLight,
              surface: kLightPurpleColor, // Màu cho Card, AppBar...
              background: kDarkPurpleColor,
              onSurface: kSecondaryColor,
              onBackground: kSecondaryColor,
            ),

            // Font chữ (Giả định dùng font hệ thống)
            textTheme: const TextTheme(
              headlineSmall: TextStyle(
                  color: kSecondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24), // "Trending"
              titleLarge: TextStyle(
                  color: kSecondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20), // "COMING SOON"
              titleMedium: TextStyle(
                  color: kSecondaryColor, fontSize: 16), // Tiêu đề AppBar
              bodyMedium: TextStyle(color: kGreyColor, fontSize: 14), // Chữ phụ
              bodySmall:
                  TextStyle(color: kGreyColor, fontSize: 12), // "Lets Explore"
              labelLarge: TextStyle(
                  color: kSecondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16), // Chữ trên nút
            ),

            // Theme cho AppBar (dùng ở các màn hình con)
            appBarTheme: const AppBarTheme(
              backgroundColor: kDarkPurpleColor,
              elevation: 0,
              iconTheme: IconThemeData(color: kSecondaryColor),
              titleTextStyle: TextStyle(
                  color: kSecondaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),

            // Theme cho Bottom Nav Bar
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.transparent, // Nền trong suốt
              elevation: 0,
              selectedItemColor: kPrimaryColor, // Icon được chọn màu hồng
              unselectedItemColor: kGreyColor,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              // Style cho NHÃN (LABEL)
              selectedLabelStyle: const TextStyle(
                  color: kSecondaryColor,
                  fontSize: 12), // Nhãn được chọn màu TRẮNG
              unselectedLabelStyle:
                  const TextStyle(color: kGreyColor, fontSize: 12),
            ),

            // Theme cho Card (quan trọng)
            cardTheme: CardThemeData(
              color: kLightPurpleColor,
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              // Bo góc tròn trịa như thiết kế
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            // Theme cho ChoiceChip (tab thể loại)
            chipTheme: ChipThemeData(
              backgroundColor: kLightPurpleColor.withOpacity(0.5),
              disabledColor: kLightPurpleColor,
              selectedColor: kPrimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              labelStyle: const TextStyle(
                  color: kGreyColor, fontWeight: FontWeight.bold),
              secondaryLabelStyle: const TextStyle(
                  color: kSecondaryColor, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.transparent),
              ),
            ),
          ),
          routerConfig: appRouter.router,
        );
      }),
    );
  }
}
