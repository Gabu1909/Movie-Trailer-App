import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../api/api_constants.dart';
import '../../models/movie.dart';
import '../../utils/ui_helpers.dart';

class KidsMovieCard extends StatelessWidget {
  final Movie movie;

  const KidsMovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => UIHelpers.navigateToMovie(context, movie.id),
      child: Container(
        width: 160, // Tăng chiều rộng chút cho thoáng
        margin: const EdgeInsets.only(
            right: 16, bottom: 10, top: 10), // Thêm top margin cho shadow
        child: Stack(
          children: [
            // 1. GLOW LAYER (Lớp phát sáng phía sau viền)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.cyanAccent,
                      Colors.purpleAccent,
                      Colors.pinkAccent
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),

            // 2. CONTENT LAYER (Nội dung chính nằm bên trong)
            Container(
              margin: const EdgeInsets.all(3), // Viền dày 3px
              decoration: BoxDecoration(
                color: Colors.black, // Nền đen để tách biệt với viền
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Poster Ảnh
                    CachedNetworkImage(
                      imageUrl:
                          '${ApiConstants.imageBaseUrlW500}${movie.posterPath}',
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey[900]),
                      errorWidget: (_, __, ___) => const Icon(Icons.error),
                    ),

                    // Gradient đen mờ dưới chân để làm nổi chữ
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.9),
                              Colors.transparent
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),

                    // Tên phim + Rating
                    Positioned(
                      bottom: 12,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 4)
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                movie.voteAverage.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
