import 'dart:math';
import 'package:flutter/material.dart';

class SnowEffect extends StatefulWidget {
  final Widget child;
  final int numberOfSnowflakes;
  final Color snowflakeColor;
  
  const SnowEffect({
    super.key,
    required this.child,
    this.numberOfSnowflakes = 100,
    this.snowflakeColor = Colors.white,
  });

  @override
  State<SnowEffect> createState() => _SnowEffectState();
}

class _SnowEffectState extends State<SnowEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Snowflake> _snowflakes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < widget.numberOfSnowflakes; i++) {
      _snowflakes.add(Snowflake(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.5 + 0.3,
        drift: _random.nextDouble() * 0.2 - 0.1,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: SnowPainter(
                    snowflakes: _snowflakes,
                    animationValue: _controller.value,
                    color: widget.snowflakeColor,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class Snowflake {
  double x;
  double y;
  final double radius;
  final double speed;
  final double drift;

  Snowflake({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.drift,
  });
}

class SnowPainter extends CustomPainter {
  final List<Snowflake> snowflakes;
  final double animationValue;
  final Color color;

  SnowPainter({
    required this.snowflakes,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (var snowflake in snowflakes) {
      snowflake.y = (snowflake.y + snowflake.speed * 0.01) % 1.0;
      snowflake.x = (snowflake.x + snowflake.drift * 0.01) % 1.0;

      final dx = snowflake.x * size.width;
      final dy = snowflake.y * size.height;

      canvas.drawCircle(Offset(dx, dy), snowflake.radius, paint);
    }
  }

  @override
  bool shouldRepaint(SnowPainter oldDelegate) => true;
}
