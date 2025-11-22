import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/custom_colors.dart';

class TrendingMovieCardPlaceholder extends StatelessWidget {
  const TrendingMovieCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final customColors = CustomColors.of(context);

    return Shimmer.fromColors(
      baseColor: customColors.shimmerBase!,
      highlightColor: customColors.shimmerHighlight!,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}