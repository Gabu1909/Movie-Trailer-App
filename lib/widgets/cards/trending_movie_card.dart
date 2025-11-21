import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../api/api_constants.dart';
import '../../models/movie.dart';
import '../../providers/favorites_provider.dart';
import '../../theme/constants.dart';
// import '../../services/feedback_service.dart'; // Import nếu có

class TrendingMovieCard extends StatelessWidget {
  final Movie movie;
  final bool isCenterItem;
  final double scrollOffset;

  const TrendingMovieCard({
    super.key,
    required this.movie,
    this.isCenterItem = false,
    this.scrollOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // --- TINH CHỈNH LẠI THÔNG SỐ CHO MƯỢT ---

    // Scale: Bên cạnh chỉ nhỏ hơn 1 chút (0.9) thay vì nhỏ xíu (0.8)
    // Điều này giúp lấp đầy khoảng trống, nhìn đỡ bị "lọt thỏm"
    final double scale = (1 - (scrollOffset.abs() * 0.1)).clamp(0.9, 1.0);

    // Opacity: Bên cạnh mờ vừa phải (0.5) để vẫn thấy được hình
    final double opacity = (1 - (scrollOffset.abs() * 0.4)).clamp(0.6, 1.0);

    // Rotation: Giảm góc xoay xuống để đỡ bị méo hình
    final double rotation = scrollOffset * -0.03 * math.pi;

    // Dịch chuyển: Kéo các thẻ lại gần nhau hơn khi scale nhỏ lại
    final double translateX = scrollOffset * 10;

    return GestureDetector(
      onTap: () {
        context.push('/movie/${movie.id}',
            extra: {'heroTag': 'trending_poster_${movie.id}'});
      },
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(rotation)
          ..translate(translateX)
          ..scale(scale),
        child: Opacity(
          opacity: opacity,
          child: Hero(
            tag: 'trending_poster_${movie.id}',
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  // 🔥 GIẢM MARGIN NGANG: Để các thẻ sát nhau hơn
                  margin:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      // Bóng đổ động
                      BoxShadow(
                        color: isCenterItem
                            ? Colors.pinkAccent
                                .withOpacity(0.5) // Bóng hồng khi ở giữa
                            : Colors.black
                                .withOpacity(0.3), // Bóng đen khi ở bên
                        blurRadius: isCenterItem ? 25 : 10,
                        spreadRadius: isCenterItem ? 2 : 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Poster
                        if (movie.posterPath != null)
                          CachedNetworkImage(
                            imageUrl:
                                '${ApiConstants.imageBaseUrlW780}${movie.posterPath}',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFF251642),
                            ),
                            errorWidget: (context, url, error) =>
                                const Center(child: Icon(Icons.movie)),
                          )
                        else
                          Container(color: Colors.grey[900]),

                        // 2. Lớp phủ tối (Dim) - Nhẹ nhàng hơn
                        Container(
                          color: Colors.black.withOpacity(
                              (scrollOffset.abs() * 0.3).clamp(0.0, 0.5)),
                        ),

                        // 3. Specular Highlight (Vệt sáng chéo)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.4],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Nút Favorite
                Positioned(
                  top: 25, // Đẩy lên cao xíu
                  right: 20,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, provider, child) {
                      final isFavorite = provider.isFavorite(movie.id);
                      return GestureDetector(
                        onTap: () => provider.toggleFavorite(movie),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isFavorite
                                ? Colors.pinkAccent.withOpacity(0.9)
                                : Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2), width: 1),
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                            size: 20,
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
