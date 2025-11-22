import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/movie.dart';
import '../cards/movie_card.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/models/cast.dart'; 
import '../../../core/api/api_constants.dart'; 

class RelatedMoviesList extends StatefulWidget {
  final String title;
  final List<dynamic>? items;
  final bool isCast;

  const RelatedMoviesList({
    super.key,
    required this.title,
    this.items,
    this.isCast = false,
  });

  @override
  State<RelatedMoviesList> createState() => _RelatedMoviesListState();
}

class _RelatedMoviesListState extends State<RelatedMoviesList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted)
        setState(() {}); 
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items == null || widget.items!.isEmpty)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 0), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              GestureDetector(
                onTap: () {
                  FeedbackService.lightImpact(context);
                  context.push('/see-all', extra: {
                    'title': widget.title,
                    'movies': widget.isCast ? null : widget.items,
                    'cast': widget.isCast ? widget.items : null,
                  });
                },
                child:
                    Text('See All', style: TextStyle(color: Colors.grey[400])),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height:
              widget.isCast ? 150 : 220, 
          child: Builder(builder: (builderContext) {
            return ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero, 
              itemCount: widget.items!.length,
              itemBuilder: (context, index) {
                double scrollOffset = 0.0;
                if (_scrollController.hasClients &&
                    _scrollController.position.hasContentDimensions) {
                  final RenderBox? renderBox =
                      builderContext.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final viewportWidth = renderBox.size.width;
                    final itemWidth =
                        widget.isCast ? (80.0 + 10.0) : (140.0 + 12.0);
                    final itemCenter = (index * itemWidth) + (itemWidth / 2);
                    final viewportCenter =
                        _scrollController.offset + (viewportWidth / 2);
                    scrollOffset =
                        (itemCenter - viewportCenter) / viewportWidth;
                  }
                }

                if (widget.isCast) {
                  final cast = widget.items![index] as Cast;
                  return _buildCastCard(context, cast, scrollOffset);
                } else {
                  final movie = widget.items![index] as Movie;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: MovieCard(movie: movie, scrollOffset: scrollOffset),
                  );
                }
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCastCard(BuildContext context, Cast cast, double scrollOffset) {
    final double normalizedOffset = scrollOffset.abs().clamp(0.0, 1.0);
    final double blurRadius = (1 - normalizedOffset) * 10 + 2; 
    final double spreadRadius = (1 - normalizedOffset) * 3; 
    final double opacity =
        (1 - normalizedOffset) * 0.3 + 0.05; 

    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    const double avatarRadius = 35.0;
    final int memCacheWidth = (avatarRadius * 2 * devicePixelRatio)
        .round(); 
    final int memCacheHeight = (avatarRadius * 2 * devicePixelRatio).round();

    return GestureDetector(
      onTap: () {
        FeedbackService.playSound(context);
        FeedbackService.lightImpact(context);
        context.push('/actor/${cast.id}', extra: cast);
      },
      child: SizedBox(
        width: 90,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent
                        .withOpacity(opacity), 
                    blurRadius: blurRadius,
                    spreadRadius: spreadRadius,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundImage: cast.profilePath != null
                    ? CachedNetworkImageProvider(
                        '${ApiConstants.imageBaseUrl}${cast.profilePath}',
                        maxWidth: memCacheWidth,
                        maxHeight: memCacheHeight,
                      )
                    : null,
                child: cast.profilePath == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cast.name,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
