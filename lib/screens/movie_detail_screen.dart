import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../api/api_constants.dart';
import '../api/api_service.dart';
import '../models/movie.dart';
import '../providers/favorites_provider.dart';
import '../providers/downloads_provider.dart';
import '../providers/watchlist_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/related_movies_list.dart';
import 'feedback_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  final String? heroTag;
  const MovieDetailScreen({super.key, required this.movieId, this.heroTag});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Future<Movie> _movieFuture;
  bool _isOverviewExpanded = false;

  @override
  void initState() {
    super.initState();
    _movieFuture = ApiService().getMovieDetail(widget.movieId);
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
      Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.black.withOpacity(0.9),
          body: Center(
            child: YoutubePlayer(
              controller: YoutubePlayerController(
                initialVideoId: trailerKey,
                flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
              ),
              progressIndicatorColor: Colors.pinkAccent,
              progressColors: const ProgressBarColors(
                playedColor: Colors.pinkAccent,
                handleColor: Colors.pinkAccent,
              ),
              bottomActions: [
                CurrentPosition(),
                ProgressBar(isExpanded: true),
                RemainingDuration(),
                const PlaybackSpeedButton(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trailer available.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150E28),
      body: FutureBuilder<Movie>(
        future: _movieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white)),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text('Movie not found',
                  style: TextStyle(color: Colors.white)),
            );
          }

          final movie = snapshot.data!;
          final director = _findCrewMember(movie.crew, 'Director');
          final screenplay = _findCrewMember(movie.crew, 'Screenplay');
          final producer = _findCrewMember(movie.crew, 'Producer');

          return CustomScrollView(
            slivers: [
              // ======= HEADER / POSTER =======
              SliverAppBar(
                pinned: true,
                expandedHeight: 420,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  Consumer<FavoritesProvider>(
                    builder: (context, fav, _) {
                      final isFav = fav.isFavorite(movie.id);
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: Colors.pinkAccent,
                        ),
                        onPressed: () {
                          FeedbackService.lightImpact(context);
                          fav.toggleFavorite(movie);
                          FeedbackService.playSound(context);
                        },
                      );
                    },
                  )
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: widget.heroTag ?? 'movie_${movie.id}',
                        child: CachedNetworkImage(
                          imageUrl:
                              '${ApiConstants.imageBaseUrlOriginal}${movie.posterPath}',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Overlay gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black87,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.5, 1],
                          ),
                        ),
                      ),
                      // Play button center
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            FeedbackService.playSound(context);
                            _playTrailer(context, movie.trailerKey);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.pinkAccent.withOpacity(0.9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pinkAccent.withOpacity(0.5),
                                  blurRadius: 25,
                                  spreadRadius: 4,
                                )
                              ],
                            ),
                            child: const Icon(Icons.play_arrow,
                                size: 60, color: Colors.white),
                          ),
                        ),
                      ),
                      // Title bottom
                      Positioned(
                        bottom: 30,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(movie.title,
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (movie.genres?.isNotEmpty ?? false)
                                  _buildTag(movie.genres!.first.name,
                                      Colors.blueAccent),
                                const SizedBox(width: 8),
                                if (movie.runtime != null)
                                  _buildTag(_formatRuntime(movie.runtime),
                                      Colors.purpleAccent),
                                const SizedBox(width: 8),
                                _buildTag(
                                    '${movie.voteAverage.toStringAsFixed(1)} ★',
                                    Colors.amber),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ======= BODY =======
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D0B3C),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Crew Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCrewInfo('Director', director),
                          _buildCrewInfo('Screenplay', screenplay),
                          _buildCrewInfo('Producer', producer),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white24, height: 30),

                      // Overview
                      Text("Overview",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent.shade100)),
                      const SizedBox(height: 8),
                      Text(
                        movie.overview,
                        style: const TextStyle(
                            color: Colors.white70, height: 1.5, fontSize: 14),
                        maxLines: _isOverviewExpanded ? null : 4,
                        overflow: _isOverviewExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                      if (movie.overview.length > 150)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              FeedbackService.lightImpact(context);
                              setState(() =>
                                  _isOverviewExpanded = !_isOverviewExpanded);
                            },
                            child: Text(
                              _isOverviewExpanded ? "View Less" : "View More",
                              style: const TextStyle(
                                  color: Colors.pinkAccent,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),

                      // CAST
                      RelatedMoviesList(
                          title: 'CAST', items: movie.cast, isCast: true),
                      const SizedBox(height: 30),

                      // Action Buttons
                      Row(
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
                                  isIn
                                      ? Icons.bookmark_added
                                      : Icons.bookmark_border,
                                  'Watchlist',
                                ),
                              );
                            },
                          ),
                          _buildActionButton(Icons.share, 'Share'),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // RELATED
                      RelatedMoviesList(
                          title: 'RELATED', items: movie.recommendations),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ======== SMALL UI HELPERS ========

  Widget _buildTag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      );

  Widget _buildCrewInfo(String title, String name) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      );

  Widget _buildActionButton(IconData icon, String label) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      );

  Widget _buildDownloadButton(Movie movie) {
    final downloads = context.watch<DownloadsProvider>();
    final status = downloads.getStatus(movie.id);
    final progress = downloads.getProgress(movie.id);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _buildButtonForStatus(status, movie, progress),
    );
  }

  Widget _buildButtonForStatus(
      DownloadStatus status, Movie movie, double progress) {
    switch (status) {
      case DownloadStatus.Downloading:
        return Column(
          key: const ValueKey('downloading'),
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    color: Colors.pinkAccent,
                    backgroundColor: Colors.white24,
                    strokeWidth: 3.0,
                  ),
                  Center(
                    child: Text('${(progress * 100).toInt()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Pause',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        );
      case DownloadStatus.Downloaded:
        return _buildActionButton(Icons.play_circle, 'Play');
      default:
        return _buildActionButton(Icons.download, 'Download');
    }
  }
}
