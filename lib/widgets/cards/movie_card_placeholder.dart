import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MovieCardPlaceholder extends StatelessWidget {
  const MovieCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.2),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white, // Màu nền cho shimmer
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 140, height: 200, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
