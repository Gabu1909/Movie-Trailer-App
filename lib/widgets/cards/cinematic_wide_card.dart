import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../api/api_constants.dart';
import '../../models/movie.dart';
import '../../utils/ui_helpers.dart';

class CinematicWideCard extends StatelessWidget {
  final Movie movie;

  const CinematicWideCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = movie.backdropPath != null
        ? '${ApiConstants.imageBaseUrlW500}${movie.backdropPath}'
        : '${ApiConstants.imageBaseUrlW500}${movie.posterPath}';

    return GestureDetector(
      onTap: () => UIHelpers.navigateToMovie(context, movie.id),
      child: Container(
        width: 300,
        height: 180,
        margin: const EdgeInsets.only(right: 16, bottom: 15),
        // 1. VIỀN GRADIENT: Chuyển sang tone VÀNG CAM (Luxury)
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFE082), // Vàng nhạt (Champagne)
              Color(0xFFFFCA28), // Vàng Amber
              Color(0xFFFF6F00), // Cam đậm (Amber Dark)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            // Glow màu Vàng Cam ấm áp
            BoxShadow(
              color: const Color(0xFFFFCA28).withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // Padding làm độ dày viền (1.5px)
        padding: const EdgeInsets.all(1.5),

        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A0933), // Nền trùng màu app
            borderRadius: BorderRadius.circular(19),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. ẢNH NỀN
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: const Color(0xFF251642)),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFF2A1B4E),
                    child: const Icon(Icons.movie, color: Colors.white54),
                  ),
                ),

                // 2. GRADIENT NỀN CHỮ
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 130,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.95),
                          Colors.black.withOpacity(0.0),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),

                // 3. NỘI DUNG
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Badge SUGGESTED (Viền vàng)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFCA28)
                                    .withOpacity(0.15), // Nền vàng nhạt
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFFFFCA28)
                                        .withOpacity(0.5)), // Viền vàng
                              ),
                              child: const Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  color: Color(0xFFFFE082), // Chữ vàng nhạt
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),

                            // Tên phim
                            Text(
                              movie.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 4)
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Rating
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Color(0xFFFFCA28),
                                    size: 16), // Sao màu vàng chuẩn
                                const SizedBox(width: 4),
                                Text(
                                  movie.voteAverage.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color:
                                        Color(0xFFFFCA28), // Điểm số màu vàng
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Nút Play (Viền vàng)
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                          border: Border.all(
                              color: const Color(0xFFFFCA28).withOpacity(0.6),
                              width: 1.5),
                        ),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: const Center(
                              child: Icon(Icons.play_arrow_rounded,
                                  color: Color(0xFFFFCA28),
                                  size: 30), // Icon màu vàng
                            ),
                          ),
                        ),
                      ),
                    ],
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
