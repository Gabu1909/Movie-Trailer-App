import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_service.dart';
import 'core/router/app_router.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/constants.dart';
import 'core/theme/custom_colors.dart';
import 'core/theme/app_themes.dart';

import 'providers/movie_provider.dart';
import 'providers/bottom_nav_visibility_provider.dart';
import 'providers/movie_detail_provider.dart';
import 'providers/search_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/downloads_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/my_reviews_provider.dart';
import 'providers/actor_detail_provider.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); 
  await LocalNotificationService.initialize(); 
  runApp(const MyApp());
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
        ChangeNotifierProvider(create: (_) => MovieProvider(ApiService())),

        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (context) => FavoritesProvider(),
          update: (context, authProvider, previous) {
            final provider = previous ?? FavoritesProvider();
            provider.setUserId(authProvider.currentUser?.id);
            return provider;
          },
        ),

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

        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(),
          update: (context, authProvider, previous) {
            final provider = previous ?? NotificationProvider();
            provider.setUserId(authProvider.currentUser?.id);
            return provider;
          },
        ),
        
        ChangeNotifierProvider(
            create: (_) => MyReviewsProvider()), 
        ChangeNotifierProvider(
            create: (_) => SearchProvider()), 
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
        final authProvider = Provider.of<AuthProvider>(context);
        final settingsProvider = Provider.of<SettingsProvider>(context);
        final appRouter = AppRouter(authProvider: authProvider);
        final selectedTheme = AppThemes.findById(settingsProvider.themeId);

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Movie App',
          themeAnimationDuration: const Duration(milliseconds: 500), 
          themeAnimationCurve: Curves.easeInOut, 
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
          darkTheme: null, 
          routerConfig: appRouter.router,
        );
      }),
    );
  }
}
