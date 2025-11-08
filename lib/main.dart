import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/movie_provider.dart';
import 'providers/downloads_provider.dart'; // 1. Import DownloadsProvider
import 'providers/watchlist_provider.dart';
import 'router/app_router.dart';
import 'theme/constants.dart'; // Import màu sắc mới

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(
            create: (_) => DownloadsProvider()), // 2. Thêm vào danh sách
      ],
      child: MaterialApp.router(
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
            labelStyle:
                const TextStyle(color: kGreyColor, fontWeight: FontWeight.bold),
            secondaryLabelStyle: const TextStyle(
                color: kSecondaryColor, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.transparent),
            ),
          ),
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
