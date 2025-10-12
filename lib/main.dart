// (Code của main.dart đã được gửi)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/movie_provider.dart';
import 'router/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng MultiProvider để cung cấp các Provider cho toàn bộ cây Widget
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        // Khởi tạo FavoritesProvider để tải dữ liệu từ database khi app khởi động
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Movie App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark, // Sử dụng theme tối
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          // Thiết lập màu cho BottomNavigationBar
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.blue, // Màu icon khi được chọn
            unselectedItemColor: Colors.white70, // Màu icon khi không được chọn
          ),
        ),
        // Sử dụng GoRouter để quản lý điều hướng
        routerConfig: AppRouter.router,
      ),
    );
  }
}
