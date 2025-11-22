import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/models/movie.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/app_constants.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final double scrollOffset; 

  const MovieCard({
    super.key,
    required this.movie,
    this.scrollOffset = 0.0,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final double normalizedOffset = widget.scrollOffset.abs().clamp(0.0, 1.0);

    final double glowOpacity =
        (1 - normalizedOffset) * AppConstants.maxGlowOpacity +
            AppConstants.defaultGlowOpacity;
    final double borderOpacity = (1 - normalizedOffset) * 0.4 + 0.1;

    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int memCacheWidth =
        (AppConstants.movieCardWidth * devicePixelRatio).round();
    final int memCacheHeight =
        (AppConstants.movieCardHeight * devicePixelRatio).round();

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

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateY(widget.scrollOffset.clamp(-1.0, 1.0) * -0.2);

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => UIHelpers.navigateToMovie(context, movie.id),
        child: AnimatedContainer(
          duration: AppConstants.shortAnimationDuration,
          curve: Curves.easeOutCubic,
          transform: _isPressed
              ? (Matrix4.identity()..scale(0.95))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          width: AppConstants.movieCardWidth,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppConstants.movieCardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(currentGlow),
                blurRadius: currentBlur,
                spreadRadius: currentSpread,
                offset: const Offset(0, 10),
              ),
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
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(
                            AppConstants.movieCardBorderRadius)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        height: 65,
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
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStarIcons(movie.voteAverage),
                                Text(
                                  movie.voteAverage.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        AppConstants.movieCardBorderRadius),
                    border: Border.all(
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

  Widget _buildStarIcons(double voteAverage) {
    final rating = voteAverage / 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star_rounded
              : index < rating
                  ? Icons.star_half_rounded
                  : Icons.star_border_rounded,
          color: Colors.amber,
          size: 14,
        );
      }),
    );
  }
}
