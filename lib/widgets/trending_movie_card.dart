import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Thêm import cho SystemSound
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/api_constants.dart';
import '../models/movie.dart';
import '../providers/favorites_provider.dart';
import '../theme/constants.dart';
import '../screens/feedback_service.dart'; // Import service mới

class TrendingMovieCard extends StatelessWidget {
  final Movie movie;
  final bool isCenterItem;
  final double scrollOffset; // Tham số mới cho hiệu ứng parallax

  const TrendingMovieCard({
    super.key,
    required this.movie,
    this.isCenterItem = false,
    this.scrollOffset = 0.0, // Giá trị mặc định
  });

  @override
  Widget build(BuildContext context) {
    // Hiệu ứng phóng to/thu nhỏ
    final double scale = (1 - (scrollOffset.abs() * 0.2)).clamp(0.8, 1.0);
    // Hiệu ứng mờ (opacity) - thay đổi mượt mà
    final double opacity = (1 - (scrollOffset.abs() * 0.4)).clamp(0.2, 1.0);
    // Hiệu ứng tối (dim) - thay đổi mượt mà
    final double dim = (scrollOffset.abs() * 0.5).clamp(0.0, 0.5);

    return GestureDetector(
      onTap: () {
        context.push('/movie/${movie.id}',
            extra: {'heroTag': 'trending_poster_${movie.id}'});
        FeedbackService.playSound(context);
        FeedbackService.lightImpact(context);
      },
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: Opacity(
          opacity: opacity,
          child: Hero(
            // <--- Hero now wraps the entire card visual
            tag: 'trending_poster_${movie.id}',
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isCenterItem
                        ? [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(0.6),
                              blurRadius: 30,
                              spreadRadius: 20,
                            ),
                          ]
                        : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (movie.posterPath != null)
                          Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // Thêm perspective
                              ..rotateY(
                                  scrollOffset * -0.5) // Xoay theo chiều Y
                              ..scale(isCenterItem
                                  ? 1.0
                                  : 0.95), // Scale nhẹ khi không ở trung tâm
                            child: CachedNetworkImage(
                              imageUrl:
                                  '${ApiConstants.imageBaseUrlOriginal}${movie.posterPath}', // ✅ dùng bản full HD
                              fit: BoxFit.cover,
                              filterQuality:
                                  FilterQuality.high, // ✅ ảnh sắc nét hơn
                              memCacheWidth:
                                  700, // ✅ cache đủ lớn (giúp tránh bị resize mờ)
                              memCacheHeight: 1050,
                              fadeInDuration: const Duration(milliseconds: 300),
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                    color: kPrimaryColor),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(child: Icon(Icons.movie)),
                            ),
                          )
                        else
                          const Center(child: Icon(Icons.movie)),
                        Container(
                          color: Colors.black.withOpacity(dim),
                        ),
                      ],
                    ),
                  ),
                ),
                // Nút Favorite (đặt ngoài Hero để nó không bị animate cùng thẻ)
                Positioned(
                  top: 30,
                  right: 24,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, provider, child) {
                      final isFavorite = provider.isFavorite(movie.id);
                      return GestureDetector(
                        // Haptic feedback and sound are handled by the IconButton in MovieDetailScreen
                        onTap: () {
                          FeedbackService.playSound(context);
                          FeedbackService.lightImpact(context);
                          provider.toggleFavorite(movie);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isFavorite
                                ? Colors.pinkAccent.withOpacity(0.8)
                                : Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                            boxShadow: isFavorite
                                ? [
                                    BoxShadow(
                                      color: Colors.pinkAccent.withOpacity(0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 300),
                            scale: isFavorite ? 1.3 : 1.0,
                            curve: Curves.elasticOut,
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
