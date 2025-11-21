import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 1. Import package
import '../../api/api_constants.dart';
import '../../models/movie.dart';
import '../../utils/ui_helpers.dart';

class RankedMovieCard extends StatefulWidget {
  final Movie movie;
  final int index;
  final double scrollOffset; // Thêm tham số mới

  const RankedMovieCard({
    super.key,
    required this.movie,
    required this.index,
    this.scrollOffset = 0.0, // Giá trị mặc định
  });

  @override
  State<RankedMovieCard> createState() => _RankedMovieCardState();
}

class _RankedMovieCardState extends State<RankedMovieCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(widget.index);

    return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          UIHelpers.navigateToMovie(context, widget.movie.id);
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: _isPressed
              ? (Matrix4.identity()..scale(0.98)) // Co lại ít hơn
              : Matrix4.identity(),
          height: 145, // Giảm chiều cao tí cho gọn
          margin: const EdgeInsets.only(bottom: 20),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. NỀN CARD (Sáng hơn & Trong hơn)
              _buildCardBackground(rankColor),

              // 2. SỐ HẠNG 3D (Rõ nét hơn)
              _buildRankNumber3D(rankColor),

              // 3. NỘI DUNG
              _buildCardContent(rankColor),
            ],
          ),
        ),
      )
      // 2. Thêm hiệu ứng vào đây
      .animate()
      .fadeIn(duration: 600.ms, curve: Curves.easeOut) // Mờ dần trong 600ms
      .slideX(begin: 0.5, duration: 600.ms, curve: Curves.easeOutCubic) // Trượt từ phải sang
      .scaleXY(begin: 0.9, duration: 600.ms, curve: Curves.easeOutCubic) // Phóng to
      .then(delay: 200.ms) // Đợi 200ms
      // Hiệu ứng "shimmer" nhẹ để làm nổi bật
      .shimmer(duration: 800.ms, color: Colors.white.withOpacity(0.1))
    ;
  }

  Widget _buildCardBackground(Color rankColor) {
    return Container(
      margin: const EdgeInsets.only(left: 20, top: 8), // Thụt vào ít hơn chút
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // Viền sáng neon
        border: Border.all(
          color: rankColor.withOpacity(0.5), // Viền rõ hơn
          width: 1.2,
        ),
        boxShadow: [
          // Shadow đen đậm để nổi bật trên nền app
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          // Glow màu rank tỏa ra xung quanh
          BoxShadow(
            color: rankColor.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      // ClipRRect để bo tròn cả phần blur bên trong
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: 15, sigmaY: 15), // Blur mạnh hơn tạo cảm giác kính dày
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rankColor.withOpacity(0.15), // Đầu trái sáng màu rank
                  const Color(0xFF2A1B4E).withOpacity(0.8), // Giữa tím đậm
                  const Color(0xFF150A28).withOpacity(0.9), // Cuối tối hẳn
                ],
                stops: const [0.0, 0.4, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankNumber3D(Color rankColor) {
    // Tính toán độ dịch chuyển cho hiệu ứng parallax
    final double parallaxOffset = widget.scrollOffset * -30;
    return Positioned(
      left: -5 + parallaxOffset, // Áp dụng parallax offset
      bottom: -22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow sau số
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: rankColor.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Số chính
          Text(
            '${widget.index + 1}',
            style: TextStyle(
              fontSize: 105,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 1,
              letterSpacing: -4,
              // Dùng Foreground gradient cho số trông kim loại hơn
              foreground: Paint()
                ..style = PaintingStyle.fill
                ..shader = LinearGradient(
                  colors: [
                    rankColor.withOpacity(0.8), // Trên sáng
                    rankColor.withOpacity(0.1), // Dưới mờ dần vào nền
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
            ),
          ),
          // Viền số (Stroke) để sắc nét
          Text(
            '${widget.index + 1}',
            style: TextStyle(
              fontSize: 105,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 1,
              letterSpacing: -4,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = rankColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(Color rankColor) {
    final releaseDate = widget.movie.releaseDate?.toString() ?? '';
    final releaseYear =
        releaseDate.isNotEmpty ? releaseDate.split('-')[0] : null;

    return Padding(
      padding:
          const EdgeInsets.only(left: 55.0, right: 16.0, top: 12, bottom: 12),
      child: Row(
        children: [
          // POSTER
          Hero(
            tag: 'rank_poster_${widget.movie.id}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  // Glow mạnh hơn cho Poster
                  BoxShadow(
                    color: rankColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                ],
                border:
                    Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl:
                      '${ApiConstants.imageBaseUrlW500}${widget.movie.posterPath}',
                  width: 90,
                  height: 135,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.black26),
                  errorWidget: (_, __, ___) => const Icon(Icons.error),
                ),
              ),
            ),
          ),

          const SizedBox(width: 18),

          // INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Badge TOP 1/2/3 Sáng bóng
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [rankColor, rankColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: rankColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    'TOP ${widget.index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors
                          .black87, // Chữ đen tương phản tốt với màu kim loại
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                Text(
                  widget.movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: rankColor, size: 18), // Sao màu rank luôn
                    const SizedBox(width: 6),
                    Text(
                      widget.movie.voteAverage.toStringAsFixed(1),
                      style: TextStyle(
                        color: rankColor, // Điểm số màu rank
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (releaseYear != null)
                      Text(
                        releaseYear,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Nút Play sáng
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: rankColor.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: rankColor,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Vàng Gold chuẩn
      case 1:
        return const Color(0xFFE0E0E0); // Bạc sáng
      case 2:
        return const Color(0xFFCD7F32); // Đồng chuẩn
      default:
        return Colors.white;
    }
  }
}
