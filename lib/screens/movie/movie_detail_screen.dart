import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_constants.dart';
import '../../models/movie.dart';
import '../../models/genre.dart';
import '../../providers/movie_detail_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/downloads_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/lists/related_movies_list.dart';
import '../../services/feedback_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  final String? heroTag;
  const MovieDetailScreen({super.key, required this.movieId, this.heroTag});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isOverviewExpanded = false;
  bool _isDataFetched = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataFetched) {
      // Dùng addPostFrameCallback để tránh setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<MovieDetailProvider>().fetchMovieDetails(widget.movieId);
        }
      });
      _isDataFetched = true;
    }
  }

  String _findCrewMember(List<Crew>? crew, String job) {
    if (crew == null) return 'N/A';
    return crew
        .firstWhere((c) => c.job == job,
            orElse: () => Crew(name: 'N/A', job: ''))
        .name;
  }

  String _formatRuntime(int? runtime) {
    if (runtime == null) return '';
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    return '${hours}h ${minutes}m';
  }

  void _playTrailer(BuildContext context, String? trailerKey) {
    if (trailerKey != null) {
      context.push(
        '/play-youtube/$trailerKey',
        extra: {'title': 'Trailer'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12002F), // Cập nhật màu nền
      body: Consumer<MovieDetailProvider>(
        builder: (context, provider, child) {
          final isLoading = provider.isLoading(widget.movieId);
          final error = provider.getError(widget.movieId);
          final movie = provider.getMovie(widget.movieId);

          if (isLoading && movie == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.pinkAccent),
                  const SizedBox(height: 20),
                  Text(
                    'Loading movie details...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          if (error != null && movie == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.pinkAccent, size: 60),
                  const SizedBox(height: 20),
                  Text(error,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          if (movie == null) {
            return const Center(
              child: Text('Movie not found',
                  style: TextStyle(color: Colors.white)),
            );
          }

          final director = _findCrewMember(movie.crew, 'Director');
          final screenplay = _findCrewMember(movie.crew, 'Screenplay');
          final producer = _findCrewMember(movie.crew, 'Producer');

          return FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () => context
                  .read<MovieDetailProvider>()
                  .fetchMovieDetails(widget.movieId, forceRefresh: true),
              color: Colors.pinkAccent,
              backgroundColor: const Color(0xFF1D0B3C),
              child: CustomScrollView(
                slivers: [
                  // ======= ENHANCED HEADER / POSTER =======
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 480,
                    backgroundColor: Colors.transparent,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 20),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Consumer<FavoritesProvider>(
                          builder: (context, fav, _) {
                            final isFav = fav.isFavorite(movie.id);
                            return IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.pinkAccent : Colors.white,
                              ),
                              onPressed: () {
                                FeedbackService.lightImpact(context);
                                fav.toggleFavorite(movie);
                                FeedbackService.playSound(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background poster with blur
                          Hero(
                            tag: widget.heroTag ?? 'movie_${movie.id}',
                            child: CachedNetworkImage(
                              imageUrl:
                                  '${ApiConstants.imageBaseUrlOriginal}${movie.posterPath}',
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Gradient overlay with enhanced colors
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.7),
                                  const Color(0xFF0A0118),
                                ], // Giữ nguyên gradient tối ở đây để làm nổi bật tiêu đề
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.4, 0.7, 1.0],
                              ),
                            ),
                          ),
                          // Glow effect around play button
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                FeedbackService.playSound(context);
                                _playTrailer(context, movie.trailerKey);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.pinkAccent.withOpacity(0.8),
                                      Colors.pinkAccent.withOpacity(0.3),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.pinkAccent.withOpacity(0.6),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.4),
                                      blurRadius: 60,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.play_arrow,
                                    size: 70, color: Colors.white),
                              ),
                            ),
                          ),
                          // Enhanced title section with glassmorphism
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: ClipRRect(
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 30, 20, 30),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.3),
                                        Colors.black.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    border: Border(
                                      top: BorderSide(
                                        color:
                                            Colors.pinkAccent.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        movie.title,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.2,
                                          letterSpacing: 0.5,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              offset: Offset(0, 2),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (movie.genres?.isNotEmpty ?? false)
                                            _buildTag(
                                              movie.genres!.first.name,
                                              Colors.blue,
                                              Icons.movie_outlined,
                                            ),
                                          if (movie.runtime != null)
                                            _buildTag(
                                              _formatRuntime(movie.runtime),
                                              Colors.purpleAccent,
                                              Icons.access_time,
                                            ),
                                          _buildTag(
                                            '${movie.voteAverage.toStringAsFixed(1)} ★',
                                            Colors.orangeAccent,
                                            Icons.star,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ======= ENHANCED BODY =======
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF12002F), // Cập nhật màu gradient
                            Color(0xFF3A0CA3), // Cập nhật màu gradient
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Crew Info Cards
                          _buildCrewSection(director, screenplay, producer),

                          const SizedBox(height: 30),

                          // Enhanced Overview Section
                          _buildSectionTitle('OVERVIEW', Icons.info_outline),
                          const SizedBox(height: 16),
                          _buildOverviewCard(movie),

                          // Genres Section (below Overview)
                          if (movie.genres != null && movie.genres!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                const Text(
                                  'GENRES',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildGenresSection(movie.genres!),
                              ],
                            ),

                          const SizedBox(height: 35),

                          // Action Buttons with enhanced design
                          _buildActionButtonsRow(movie),

                          const SizedBox(height: 35),

                          // CAST Section
                          RelatedMoviesList(
                            title: 'CAST',
                            items: movie.cast,
                            isCast: true,
                          ),
                          const SizedBox(height: 35),

                          // RELATED Section
                          RelatedMoviesList(
                            title: 'RELATED',
                            items: movie.recommendations,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ======== ENHANCED UI COMPONENTS ========

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.pinkAccent, Colors.purpleAccent],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCrewSection(
      String director, String screenplay, String producer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withOpacity(0.1),
            Colors.purpleAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.pinkAccent.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildCrewInfo('Director', director, Icons.videocam)),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(child: _buildCrewInfo('Writer', screenplay, Icons.edit)),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
              child:
                  _buildCrewInfo('Producer', producer, Icons.movie_creation)),
        ],
      ),
    );
  }

  Widget _buildCrewInfo(String title, String name, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.pinkAccent, size: 20),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildGenresSection(List<Genre> genres) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: genres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purpleAccent.withOpacity(0.2),
                Colors.pinkAccent.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.purpleAccent.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: Text(
            genre.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverviewCard(Movie movie) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie.overview,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.6,
              fontSize: 14.5,
              letterSpacing: 0.3,
            ),
            maxLines: _isOverviewExpanded ? null : 5,
            overflow: _isOverviewExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
          if (movie.overview.length > 150)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  FeedbackService.lightImpact(context);
                  setState(() => _isOverviewExpanded = !_isOverviewExpanded);
                },
                icon: Icon(
                  _isOverviewExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.pinkAccent,
                ),
                label: Text(
                  _isOverviewExpanded ? "Show Less" : "Show More",
                  style: const TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow(Movie movie) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withOpacity(0.05),
            Colors.purpleAccent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.pinkAccent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDownloadButton(movie),
          Consumer<WatchlistProvider>(
            builder: (_, watchlist, __) {
              final isIn = watchlist.isInWatchlist(movie.id);
              return GestureDetector(
                onTap: () {
                  FeedbackService.playSound(context);
                  watchlist.toggleWatchlist(movie);
                },
                child: _buildActionButton(
                  isIn ? Icons.bookmark : Icons.bookmark_border,
                  'Watchlist',
                  isIn,
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () => _shareMovie(context, movie),
            child: _buildActionButton(Icons.share, 'Share', false),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, bool isActive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Colors.pinkAccent, Colors.purpleAccent],
                  )
                : null,
            color: isActive ? null : Colors.pinkAccent.withOpacity(0.15),
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton(Movie movie) {
    final downloads = context.watch<DownloadsProvider>();
    final status = downloads.getStatus(movie.id);
    final progress = downloads.getProgress(movie.id);

    return GestureDetector(
      onTap: () => _handleDownloadTap(context, status, movie),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildButtonForStatus(status, movie, progress),
      ),
    );
  }

  Widget _buildButtonForStatus(
      DownloadStatus status, Movie movie, double progress) {
    switch (status) {
      case DownloadStatus.Downloading:
        return Column(
          key: const ValueKey('downloading'),
          children: [
            _buildProgressIndicator(progress),
            const SizedBox(height: 10),
            const Text(
              'Pause',
              style: TextStyle(
                color: Colors.pinkAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case DownloadStatus.Paused:
        return Column(
          key: const ValueKey('paused'),
          children: [
            _buildProgressIndicator(progress),
            const SizedBox(height: 10),
            const Text(
              'Resume',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        );
      case DownloadStatus.Downloaded:
        return _buildActionButton(Icons.play_circle, 'Play', true);
      case DownloadStatus.Error:
        return _buildActionButton(Icons.error_outline, 'Retry', false);
      default:
        return _buildActionButton(Icons.download, 'Download', false);
    }
  }

  Widget _buildProgressIndicator(double progress) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            color: Colors.pinkAccent,
            backgroundColor: Colors.white.withOpacity(0.2),
            strokeWidth: 4.0,
          ),
          Center(
            child: Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDownloadTap(
      BuildContext context, DownloadStatus status, Movie movie) {
    final provider = context.read<DownloadsProvider>();
    FeedbackService.playSound(context);

    switch (status) {
      case DownloadStatus.Downloading:
        provider.pauseDownload(movie.id);
        break;
      case DownloadStatus.Paused:
      case DownloadStatus.Error:
        provider.resumeDownload(movie);
        break;
      case DownloadStatus.Downloaded:
        final filePath = provider.getFilePath(movie.id);
        if (filePath != null) {
          context.push('/play-local/${movie.id}',
              extra: {'filePath': filePath, 'title': movie.title});
        }
        break;
      case DownloadStatus.NotDownloaded:
        _showDownloadQualitySheet(context, movie);
        break;
    }
  }

  void _showDownloadQualitySheet(BuildContext context, Movie movie) {
    final provider = context.read<DownloadsProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D0B3C), Color(0xFF0A0118)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Select Download Quality',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              _buildQualityOption(
                sheetContext,
                provider,
                movie,
                Icons.high_quality,
                'High Quality',
                'Best quality, largest file size',
                DownloadQuality.high,
                Colors.pinkAccent,
              ),
              _buildQualityOption(
                sheetContext,
                provider,
                movie,
                Icons.hd_outlined,
                'Medium Quality',
                'Good quality, smaller file size',
                DownloadQuality.medium,
                Colors.purpleAccent,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualityOption(
    BuildContext sheetContext,
    DownloadsProvider provider,
    Movie movie,
    IconData icon,
    String title,
    String subtitle,
    DownloadQuality quality,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            provider.downloadMovie(movie, quality);
            Navigator.pop(sheetContext);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareMovie(BuildContext context, Movie movie) {
    FeedbackService.playSound(context);
    FeedbackService.lightImpact(context);

    // Tạm thời disable share vì package lỗi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share feature temporarily disabled')),
    );
  }
}
