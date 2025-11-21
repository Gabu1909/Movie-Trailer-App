import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math'; // Import để sử dụng Random
import 'package:provider/provider.dart';
import '../../providers/movie_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Controller cho hiệu ứng mưa sao băng
  late AnimationController _particleController;
  final List<_Particle> _particles = [];
  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // --- Khởi tạo cho hiệu ứng mưa sao băng ---
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _initializeParticles();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutCubic,
      ),
    );

    _logoController.forward();
    _audioPlayer.play(AssetSource('sounds/logo_swoosh.mp3'));

    // Chỉ đợi một khoảng thời gian cố định để animation hiển thị,
    // không chờ việc tải dữ liệu ở đây để tránh làm khựng UI.
    // Việc tải dữ liệu đã được MovieProvider tự động thực hiện ở dưới nền.
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  void _initializeParticles() {
    final size = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final random = Random();
    // Danh sách các màu sắc cho tuyết để phù hợp với chủ đề
    final List<Color> snowColors = [
      Colors.white,
      Colors.purple.shade100, // Tăng độ đậm của màu tím
      Colors.lightBlue.shade200, // Tăng độ đậm của màu xanh
    ];

    for (int i = 0; i < 150; i++) {
      final baseColor = snowColors[random.nextInt(snowColors.length)];
      _particles.add(_Particle(
        position: Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        color: baseColor.withOpacity(random.nextDouble() * 0.6 + 0.2),
        speed: random.nextDouble() * 1.5 + 0.5,
        size: random.nextDouble() * 1.5 + 1.0,
      ));
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- Ảnh nền chính (dọc) ---
          Image.asset(
            'assets/background.png', // 👉 Đổi tên theo file bạn đã lưu
            fit: BoxFit.cover,
          ),

          // --- Lớp hiệu ứng mưa sao băng ---
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter:
                    _ParticlePainter(_particles, _particleController.value),
              );
            },
          ),

          // --- Lớp overlay tím mờ giúp chữ rõ hơn ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2B124C).withOpacity(0.7),
                  const Color(0xFF5B2A9B).withOpacity(0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // --- Hiệu ứng Logo & Text ---
          Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Giữ lại slogan
                    Text(
                      'Your Cinematic Universe',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.85),
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.2),
                    ),
                  ], // Đóng children
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Class để lưu thông tin một hạt (sao băng)
class _Particle {
  Offset position;
  Color color;
  double speed;
  double size;

  _Particle({
    required this.position,
    required this.color,
    required this.speed,
    required this.size,
  });
}

// CustomPainter để vẽ các hạt
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue; // Dùng để cập nhật vị trí
  final Random _random = Random();

  _ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      // Cập nhật vị trí của hạt tuyết
      // Thêm hiệu ứng gió thổi nhẹ sang phải
      const windSpeed = 0.5; // Tăng tốc độ gió để hiệu ứng rõ hơn
      // Thêm chuyển động uốn lượn theo chiều ngang sử dụng sin
      final horizontalSway = sin(particle.position.dy / 100) * 0.3;
      particle.position = Offset(
        particle.position.dx +
            horizontalSway +
            windSpeed, // Cộng thêm tốc độ gió
        particle.position.dy + particle.speed,
      );

      // Nếu hạt tuyết đi ra khỏi màn hình, tái tạo nó ở một vị trí ngẫu nhiên trên đỉnh
      if (particle.position.dy > size.height) {
        particle.position = Offset(_random.nextDouble() * size.width, -20.0);
        particle.speed = _random.nextDouble() * 1.5 + 0.5;
      } else if (particle.position.dx > size.width) {
        particle.position = Offset(0, particle.position.dy);
      } else if (particle.position.dx < 0) {
        particle.position = Offset(size.width, particle.position.dy);
      }

      // Tính toán hiệu ứng lấp lánh (dao động độ trong suốt)
      // Sử dụng một pha độc đáo cho mỗi hạt dựa trên vị trí của nó để làm cho các hạt lấp lánh không đồng bộ
      double sparklePhase =
          (particle.position.dx + particle.position.dy) * 0.01;
      // Giá trị từ 0 đến 1, dao động theo thời gian và pha của hạt
      double sparkleFactor =
          (sin(animationValue * 2 * pi + sparklePhase) + 1) / 2;

      // Điều chỉnh độ trong suốt dựa trên sparkleFactor.
      // Độ trong suốt sẽ dao động từ 70% đến 100% độ trong suốt ban đầu của hạt.
      double currentOpacity =
          particle.color.opacity * (0.7 + sparkleFactor * 0.3);
      paint.color = particle.color.withOpacity(currentOpacity.clamp(0.0, 1.0));
      // Vẽ hạt tuyết dưới dạng hình tròn
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Luôn vẽ lại để tạo animation
  }
}
