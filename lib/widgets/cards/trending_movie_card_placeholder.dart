import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/custom_colors.dart'; // Đường dẫn này đã đúng sau khi di chuyển file

/// Widget này tạo ra một khung chờ có hiệu ứng shimmer,
/// mô phỏng hình dạng của TrendingMovieCard.
class TrendingMovieCardPlaceholder extends StatelessWidget {
  const TrendingMovieCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final customColors = CustomColors.of(context);

    // Sử dụng Shimmer.fromColors để tạo hiệu ứng lấp lánh
    return Shimmer.fromColors(
      baseColor: customColors.shimmerBase!, // Lấy màu từ theme
      highlightColor: customColors.shimmerHighlight!, // Lấy màu từ theme
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
