import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/models/movie.dart';
import '../../../providers/favorites_provider.dart';
import '../../../core/theme/constants.dart';

class TrendingMovieCard extends StatelessWidget {
  final Movie movie;
  final bool isCenterItem;
  final double scrollOffset;
  final void Function(bool isNowFavorite)? onFavoriteToggled;

  const TrendingMovieCard({
    super.key,
    required this.movie,
    this.isCenterItem = false,
    this.scrollOffset = 0.0,
    this.onFavoriteToggled,
  });

  @override
  Widget build(BuildContext context) {
    final double scale = (1 - (scrollOffset.abs() * 0.1)).clamp(0.9, 1.0);

    final double opacity = (1 - (scrollOffset.abs() * 0.4)).clamp(0.6, 1.0);

    final double rotation = scrollOffset * -0.03 * math.pi;

    final double translateX = scrollOffset * 10;

    return GestureDetector(
      onTap: () {
        if (movie.mediaType == 'tv') {
          context.push(
            '/tv/${movie.id}',
            extra: {'heroTag': 'trending_tv_${movie.id}'},
          );
        } else {
          context.push(
            '/movie/${movie.id}',
            extra: {'heroTag': 'trending_poster_${movie.id}'},
          );
        }
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isCenterItem
                            ? Colors.pinkAccent.withOpacity(0.5)
                            : Colors.black.withOpacity(0.3),
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
                        Container(
                          color: Colors.black.withOpacity(
                              (scrollOffset.abs() * 0.3).clamp(0.0, 0.5)),
                        ),
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
                Positioned(
                  top: 25,
                  right: 20,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, provider, child) {
                      final isFavorite = provider.isFavorite(movie.id);
                      return GestureDetector(
                        onTap: () async {
                          final wasFavorite = provider.isFavorite(movie.id);
                          await provider.toggleFavorite(movie);
                          final isNowFavorite = provider.isFavorite(movie.id);
                          if (onFavoriteToggled != null &&
                              !wasFavorite &&
                              isNowFavorite) {
                            onFavoriteToggled!(true);
                          }
                        },
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
