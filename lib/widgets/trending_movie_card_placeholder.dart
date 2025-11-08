import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget này tạo ra một khung chờ có hiệu ứng shimmer,
/// mô phỏng hình dạng của TrendingMovieCard.
class TrendingMovieCardPlaceholder extends StatelessWidget {
  const TrendingMovieCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng Shimmer.fromColors để tạo hiệu ứng lấp lánh
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!, // Màu nền tối của khung
      highlightColor: Colors.grey[800]!, // Màu sáng lấp lánh di chuyển
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          // Màu này sẽ được che bởi hiệu ứng shimmer
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
