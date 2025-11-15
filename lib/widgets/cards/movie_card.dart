import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../api/api_constants.dart';
import '../../models/movie.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/app_constants.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final double scrollOffset; // Dùng cho 3D tilt, glow, và viền neon

  const MovieCard({
    super.key,
    required this.movie,
    this.scrollOffset = 0.0,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

// Bỏ SingleTickerProviderStateMixin vì AnimatedContainer tự xử lý
class _MovieCardState extends State<MovieCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final double normalizedOffset = widget.scrollOffset.abs().clamp(0.0, 1.0);

    // Tính toán các giá trị động
    // Càng ở gần trung tâm (offset = 0), giá trị càng cao
    final double glowOpacity =
        (1 - normalizedOffset) * AppConstants.maxGlowOpacity +
            AppConstants.defaultGlowOpacity;
    // Nâng cấp 3: Viền neon sẽ sáng nhất ở trung tâm
    final double borderOpacity = (1 - normalizedOffset) * 0.4 + 0.1;

    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int memCacheWidth =
        (AppConstants.movieCardWidth * devicePixelRatio).round();
    final int memCacheHeight =
        (AppConstants.movieCardHeight * devicePixelRatio).round();

    // Nâng cấp 2: Tính toán hiệu ứng đổ bóng khi nhấn
    // Khi nhấn, glow sẽ sáng hơn và gần hơn
    final double currentGlow =
        _isPressed ? (glowOpacity * 1.5).clamp(0.0, 1.0) : glowOpacity;
    final double currentBlur = _isPressed
        ? AppConstants.pressedBlurRadius
        : AppConstants.defaultBlurRadius;
    final double currentSpread = _isPressed
        ? AppConstants.pressedGlowSpreadRadius
        : AppConstants.glowSpreadRadius;
    final double currentBlackOpacity = _isPressed ? 0.6 : 0.4;
    final double currentBlackBlur = _isPressed ? 12 : 20;

    // Nâng cấp 1: Hiệu ứng 3D "Cover Flow"
    // Thẻ sẽ xoay nhẹ dựa trên vị trí cuộn
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Kích hoạt phối cảnh 3D
      ..rotateY(widget.scrollOffset.clamp(-1.0, 1.0) *
          -0.2); // Xoay nhẹ (điều chỉnh -0.2)

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => UIHelpers.navigateToMovie(context, movie.id),

        // Nâng cấp 2: Dùng AnimatedContainer để
        // (1) Co giãn mượt mà (scale)
        // (2) Thay đổi bóng đổ (shadow) mượt mà
        child: AnimatedContainer(
          duration: AppConstants.shortAnimationDuration,
          curve: Curves.easeOutCubic,
          transform: _isPressed
              ? (Matrix4.identity()..scale(0.95)) // Co lại khi nhấn
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          width: AppConstants.movieCardWidth,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppConstants.movieCardBorderRadius),
            boxShadow: [
              // Shadow 1: Hiệu ứng Glow màu hồng (động)
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(currentGlow),
                blurRadius: currentBlur,
                spreadRadius: currentSpread,
                offset: const Offset(0, 10),
              ),
              // Shadow 2: Hiệu ứng đổ bóng đen (động)
              BoxShadow(
                color: Colors.black.withOpacity(currentBlackOpacity),
                blurRadius: currentBlackBlur,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(AppConstants.movieCardBorderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 🎞 Poster ảnh
                CachedNetworkImage(
                  imageUrl: '${ApiConstants.imageBaseUrl}${movie.posterPath}',
                  fit: BoxFit.cover,
                  memCacheWidth: memCacheWidth,
                  memCacheHeight: memCacheHeight,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[850]!,
                    highlightColor: Colors.grey[800]!,
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 50,
                  ),
                ),

                // 🌫 Overlay gradient từ trên xuống
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // ✨ Glass blur info box (Tinh chỉnh lại)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(
                            AppConstants.movieCardBorderRadius)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        height: 65, // Giảm chiều cao một chút
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          border: Border(
                            top: BorderSide(
                              color: Colors.pinkAccent.withOpacity(0.25),
                              width: 1.0,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              movie.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15, // Giảm font size một chút
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Dùng MainAxisAlignment.spaceBetween (thay vì Spacer)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Chỉ hiển thị các ngôi sao
                                _buildStarIcons(movie.voteAverage),
                                // Hiển thị điểm số ở bên phải
                                Text(
                                  movie.voteAverage.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11, // Giảm font size
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 💡 Nâng cấp 3: Viền neon động
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        AppConstants.movieCardBorderRadius),
                    border: Border.all(
                      // Opacity của viền thay đổi theo vị trí cuộn
                      color: Colors.pinkAccent.withOpacity(borderOpacity),
                      width: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Đổi tên hàm để chỉ build các icon sao
  Widget _buildStarIcons(double voteAverage) {
    final rating = voteAverage / 2; // Chuyển đổi thang điểm 10 thành 5
    return Row(
      mainAxisSize: MainAxisSize.min, // ← Quan trọng: Thu nhỏ Row
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star_rounded // Sao tròn đầy
              : index < rating
                  ? Icons.star_half_rounded // Nửa sao tròn
                  : Icons.star_border_rounded, // Viền sao tròn
          color: Colors.amber,
          size: 14, // Giảm size để vừa hơn
        );
      }),
    );
  }
}
