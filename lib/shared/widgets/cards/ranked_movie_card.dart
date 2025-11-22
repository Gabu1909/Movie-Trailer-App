import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/models/movie.dart';
import '../../utils/ui_helpers.dart';

class RankedMovieCard extends StatefulWidget {
  final Movie movie;
  final int index;
  final double scrollOffset;

  const RankedMovieCard({
    super.key,
    required this.movie,
    required this.index,
    this.scrollOffset = 0.0,
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
        transform:
            _isPressed ? (Matrix4.identity()..scale(0.98)) : Matrix4.identity(),
        height: 145,
        margin: const EdgeInsets.only(bottom: 20),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            _buildCardBackground(rankColor),
            _buildRankNumber3D(rankColor),
            _buildCardContent(rankColor),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideX(begin: 0.5, duration: 600.ms, curve: Curves.easeOutCubic)
        .scaleXY(begin: 0.9, duration: 600.ms, curve: Curves.easeOutCubic)
        .then(delay: 200.ms)
        .shimmer(duration: 800.ms, color: Colors.white.withOpacity(0.1));
  }

  Widget _buildCardBackground(Color rankColor) {
    return Container(
      margin: const EdgeInsets.only(left: 20, top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: rankColor.withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: rankColor.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rankColor.withOpacity(0.15),
                  const Color(0xFF2A1B4E).withOpacity(0.8),
                  const Color(0xFF150A28).withOpacity(0.9),
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
    final double parallaxOffset = widget.scrollOffset * -30;
    return Positioned(
      left: -5 + parallaxOffset,
      bottom: -22,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
          Text(
            '${widget.index + 1}',
            style: TextStyle(
              fontSize: 105,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 1,
              letterSpacing: -4,
              foreground: Paint()
                ..style = PaintingStyle.fill
                ..shader = LinearGradient(
                  colors: [
                    rankColor.withOpacity(0.8),
                    rankColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
            ),
          ),
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
          Hero(
            tag: 'rank_poster_${widget.movie.id}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                      color: Colors.black87,
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
                    Icon(Icons.star_rounded, color: rankColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      widget.movie.voteAverage.toStringAsFixed(1),
                      style: TextStyle(
                        color: rankColor,
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
        return const Color(0xFFFFD700);
      case 1:
        return const Color(0xFFE0E0E0);
      case 2:
        return const Color(0xFFCD7F32);
      default:
        return Colors.white;
    }
  }
}
