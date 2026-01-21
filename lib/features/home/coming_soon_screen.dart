import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/api/api_constants.dart';
import '../../core/models/movie.dart';
import '../../providers/movie_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../core/services/feedback_service.dart';

class ComingSoonScreen extends StatefulWidget {
  const ComingSoonScreen({super.key});

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _bgController;
  late Animation<Alignment> _beginAlignmentAnimation;
  late Animation<Alignment> _endAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _beginAlignmentAnimation =
        AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight)
            .animate(_bgController);
    _endAlignmentAnimation =
        AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft)
            .animate(_bgController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_onScroll);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MovieProvider>().fetchMoreUpcomingMovies();
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF12002F),
                  Color(0xFF3A0CA3),
                  Color(0xFF7209B7),
                ],
                begin: _beginAlignmentAnimation.value,
                end: _endAlignmentAnimation.value,
              ),
            ),
            child: child,
          ),
        );
      },
      child: Consumer<MovieProvider>(
        builder: (context, movieProvider, child) {
          return RefreshIndicator(
            onRefresh: () => movieProvider.fetchAllData(),
            color: Colors.pinkAccent,
            backgroundColor: const Color(0xFF1D0B3C),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _buildCustomHeader(context),
                ),
                if (movieProvider.isLoading &&
                    movieProvider.upcomingMovies.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.pinkAccent,
                      ),
                    ),
                  )
                else if (movieProvider.upcomingMovies.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(),
                  )
                else
                  _buildMovieList(movieProvider.upcomingMovies),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            const Text(
              'Coming Soon',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_creation_outlined,
              color: Colors.white54, size: 80),
          const SizedBox(height: 16),
          const Text(
            'No upcoming movies found.',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieList(List<Movie> movies) {
    final provider = context.watch<MovieProvider>();
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: true);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == movies.length) {
            return provider.isFetchingMoreUpcoming
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Colors.pinkAccent)),
                  )
                : const SizedBox(height: 40);
          }
          final movie = movies[index];
          final isFavorite = favoritesProvider.isFavorite(movie.id);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              children: [
                _EnhancedMovieCard(
                  movie: movie,
                  scrollController: _scrollController,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.pinkAccent : Colors.white,
                    ),
                    tooltip: isFavorite
                        ? 'Remove from Favorites'
                        : 'Add to Favorites',
                    onPressed: () async {
                      await favoritesProvider.toggleFavorite(movie);
                      if (!isFavorite) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to Favorites successfully!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
        childCount: movies.length + 1,
      ),
    );
  }
}

class _EnhancedMovieCard extends StatefulWidget {
  final Movie movie;
  final ScrollController scrollController;

  const _EnhancedMovieCard({
    required this.movie,
    required this.scrollController,
  });

  @override
  State<_EnhancedMovieCard> createState() => _EnhancedMovieCardState();
}

class _EnhancedMovieCardState extends State<_EnhancedMovieCard> {
  bool _isPressed = false;
  final GlobalKey _cardKey = GlobalKey();

  String getDaysUntilRelease() {
    if (widget.movie.releaseDate == null) return '';
    final now = DateTime.now();
    final releaseDay = DateUtils.dateOnly(widget.movie.releaseDate!);
    final today = DateUtils.dateOnly(now);
    final difference = releaseDay.difference(today).inDays;

    if (difference < 0) return 'Released';
    if (difference == 0) return 'Today!';
    if (difference == 1) return 'Tomorrow';
    return 'In $difference days';
  }

  Color _getReleaseDateColor(DateTime? releaseDate) {
    if (releaseDate == null) return Colors.grey;

    final now = DateTime.now();
    final difference = releaseDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.grey.shade600;
    } else if (difference <= 7) {
      return Colors.redAccent.shade200;
    } else if (difference <= 30) {
      return Colors.orangeAccent.shade400;
    } else if (difference <= 90) {
      return Colors.blueAccent.shade200;
    }
    return Colors.purpleAccent.shade100;
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int cacheWidth = (120 * devicePixelRatio).round();
    final int cacheHeight = (180 * devicePixelRatio).round();
    final daysUntilRelease = getDaysUntilRelease();
    final releaseDateColor = _getReleaseDateColor(movie.releaseDate);

    return GestureDetector(
      key: _cardKey,
      onTap: () {
        FeedbackService.lightImpact(context);
        FeedbackService.playSound(context);
        context.push('/movie/${movie.id}',
            extra: {'heroTag': 'coming_soon_${movie.id}'});
      },
      onLongPressStart: (details) {
        setState(() => _isPressed = true);
        _showContextMenu(details);
      },
      onLongPressEnd: (_) => setState(() => _isPressed = false),
      onLongPressCancel: () => setState(() => _isPressed = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: _isPressed
                ? (Matrix4.identity()..scale(0.98))
                : Matrix4.identity(),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _isPressed
                      ? Colors.pinkAccent.withOpacity(0.4)
                      : Colors.black.withOpacity(0.3),
                  blurRadius: _isPressed ? 20 : 15,
                  spreadRadius: _isPressed ? 3 : 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'coming_soon_${movie.id}',
                        child: _buildParallaxPoster(cacheWidth, cacheHeight),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (movie.releaseDate != null)
                                    _buildInfoChip(
                                      icon: Icons.calendar_today,
                                      text: DateFormat.yMMMd()
                                          .format(movie.releaseDate!),
                                      color: releaseDateColor,
                                    ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    icon: Icons.star_rounded,
                                    text: movie.voteAverage.toStringAsFixed(1),
                                    color: Colors.amber,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                movie.overview,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    height: 1.4),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (daysUntilRelease.isNotEmpty)
            Positioned(
              top: -10,
              right: 12,
              child: _buildReleaseBadge(daysUntilRelease),
            ),
        ],
      ),
    );
  }

  Widget _buildParallaxPoster(int cacheWidth, int cacheHeight) {
    return SizedBox(
      width: 120,
      height: 180,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
        child: Flow(
          delegate: _ParallaxFlowDelegate(
            scrollable: Scrollable.of(context),
            listItemContext: context,
          ),
          children: [
            Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl:
                      '${ApiConstants.imageBaseUrl}${widget.movie.posterPath}',
                  fit: BoxFit.cover,
                  memCacheWidth: cacheWidth,
                  memCacheHeight: cacheHeight,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[850]!,
                    highlightColor: Colors.grey[700]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[850],
                    child: const Icon(Icons.movie,
                        color: Colors.white38, size: 40),
                  ),
                ),
                _buildGenreOverlayOnPoster(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreOverlayOnPoster() {
    if (widget.movie.genres == null || widget.movie.genres!.isEmpty) {
      return const SizedBox.shrink();
    }

    final genreText =
        widget.movie.genres!.take(2).map((g) => g.name).join(' • ');

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.85),
              Colors.transparent,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Text(
          genreText,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                blurRadius: 3.0,
                color: Colors.black,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
      {required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseBadge(String text) {
    Color badgeColor;
    IconData icon;

    if (text.contains('Today')) {
      badgeColor = Colors.green.shade400;
      icon = Icons.celebration_rounded;
    } else if (text.contains('Tomorrow')) {
      badgeColor = Colors.blue.shade400;
      icon = Icons.fast_forward_rounded;
    } else if (text == 'Released') {
      badgeColor = Colors.grey.shade600;
      icon = Icons.check_circle_outline_rounded;
    } else {
      badgeColor = Colors.orange.shade400;
      icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badgeColor, badgeColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(LongPressStartDetails details) {
    FeedbackService.lightImpact(context);
    final watchlistProvider = context.read<WatchlistProvider>();
    final isInWatchlist = watchlistProvider.isInWatchlist(widget.movie.id);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      color: const Color(0xFF2C1D4D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      items: [
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              watchlistProvider.toggleWatchlist(widget.movie);
            });
          },
          child: _buildContextMenuItem(
            icon: isInWatchlist
                ? Icons.bookmark_remove_outlined
                : Icons.bookmark_add_outlined,
            text: isInWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist',
            color: isInWatchlist ? Colors.red : Colors.pinkAccent,
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              final movieUrl =
                  'https://www.themoviedb.org/movie/${widget.movie.id}';
              final shareText =
                  'Check out this upcoming movie: ${widget.movie.title}!\n\nFind out more here: $movieUrl';
              Share.share(shareText,
                  subject: 'Movie Recommendation: ${widget.movie.title}');
            });
          },
          child: _buildContextMenuItem(
            icon: Icons.share_outlined,
            text: 'Share',
            color: Colors.blue,
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              context.push('/movie/${widget.movie.id}',
                  extra: {'heroTag': 'coming_soon_${widget.movie.id}'});
            });
          },
          child: _buildContextMenuItem(
            icon: Icons.info_outline,
            text: 'View Details',
            color: Colors.purpleAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildContextMenuItem(
      {required IconData icon, required String text, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ParallaxFlowDelegate extends FlowDelegate {
  final ScrollableState scrollable;
  final BuildContext listItemContext;

  _ParallaxFlowDelegate({
    required this.scrollable,
    required this.listItemContext,
  }) : super(repaint: scrollable.position);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return BoxConstraints.tightFor(
      width: constraints.maxWidth,
      height: constraints.maxHeight * 1.4,
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final scrollableBox = scrollable.context.findRenderObject() as RenderBox;
    final listItemBox = listItemContext.findRenderObject() as RenderBox;

    final listItemOffset = listItemBox.localToGlobal(
        listItemBox.size.centerLeft(Offset.zero),
        ancestor: scrollableBox);
    final viewportDimension = scrollable.position.viewportDimension;
    final scrollFraction =
        (listItemOffset.dy / viewportDimension).clamp(0.0, 1.0);

    final verticalAlignment = Alignment(0.0, scrollFraction * 2 - 1);
    final backgroundMatrix =
        Matrix4.translationValues(0.0, verticalAlignment.y * 30.0, 0.0);
    context.paintChild(0, transform: backgroundMatrix);
  }

  @override
  bool shouldRepaint(_ParallaxFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
        listItemContext != oldDelegate.listItemContext;
  }
}
