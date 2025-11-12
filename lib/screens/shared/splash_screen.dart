import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // Import provider
import '../../providers/movie_provider.dart'; // Import MovieProvider

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this, // Thời gian cho toàn bộ hiệu ứng
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8,
          curve: Curves.easeIn), // Mờ dần trong 80% thời gian
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0,
          curve: Curves.elasticOut), // Phóng to với hiệu ứng đàn hồi
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // Bắt đầu từ dưới lên một chút
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0,
          curve: Curves.easeOutCubic), // Trượt lên mượt mà
    ));

    _controller.forward(); // Bắt đầu animation

    // Lấy Future từ MovieProvider để chờ dữ liệu tải xong
    final movieInitializationFuture =
        context.read<MovieProvider>().initializationComplete;

    // Chờ cả animation (controller) và dữ liệu tải xong
    Future.wait([
      _controller.forward(), // Chờ animation hoàn tất
      movieInitializationFuture,
    ]).then((_) {
      if (mounted) {
        context.go('/home'); // Chuyển đến màn hình chính
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B124C), Color(0xFF5B2A9B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Thay thế bằng logo của bạn
                    Image.asset('assets/logo.png',
                        width: 150), // Sử dụng logo từ assets
                    const SizedBox(height: 24),
                    const Text('Movie App',
                        style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
