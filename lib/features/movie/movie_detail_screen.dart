import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_constants.dart';
import '../../../core/models/movie.dart';
import '../../../core/models/review.dart';
import '../../../core/models/genre.dart';
import '../../../core/models/app_notification.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/movie_detail_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../providers/downloads_provider.dart';
import '../../../providers/watchlist_provider.dart';
import '../../providers/notification_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/models/cast.dart';
import '../../../shared/widgets/cards/cinematic_wide_card.dart';
import '../../../shared/widgets/cards/trailer_card.dart';
import '../../../shared/widgets/text/section_header.dart'; 
import '../../../shared/widgets/forms/add_review_box.dart'; 
import '../../../core/data/database_helper.dart'; 

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  final String? heroTag;
  final bool scrollToMyReview; 
  final String contentType; 
  const MovieDetailScreen({super.key, required this.movieId, this.heroTag, this.scrollToMyReview = false, this.contentType = 'movie'});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isOverviewExpanded = false;
  bool _showAllTrailers = false; 
  bool _isDataFetched = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController(); 
  final GlobalKey _myReviewKey = GlobalKey(); 

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
    _scrollController.dispose(); 
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataFetched) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final authProvider = context.read<AuthProvider>();
          context
              .read<MovieDetailProvider>()
              .fetchMovieDetails(widget.movieId, currentUser: authProvider.currentUser, contentType: widget.contentType)
              .then((_) {
            if (widget.scrollToMyReview && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToMyReview());
            }
          });
        }
      });
      _isDataFetched = true;
    }
  }

  String _formatRuntime(int? runtime) {
    if (runtime == null) return '';
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    return '${hours}h ${minutes}m'; 
  }

  void _scrollToMyReview() {
    final context = _myReviewKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  String _findCrewMember(List<Crew>? crew, String job) {
    if (crew == null) return 'N/A';
    return crew
        .firstWhere((c) => c.job == job,
            orElse: () => Crew(name: 'N/A', job: ''))
        .name;
  }

  String _formatRuntimeLikeImage(int? runtime) {
    if (runtime == null) return '';
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    return '$hours:$minutes Hour';
  }

  void _playTrailer(BuildContext context, String? trailerKey) {
    if (trailerKey != null) {
      context.push(
        '/play-youtube/$trailerKey',
        extra: {'title': 'Trailer'},
      );
    }
  }

  PopupMenuEntry<String> _buildPopupMenuItem(
      IconData icon, String title, String value,
      {bool enabled = true}) {
    return PopupMenuItem<String>(
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, color: enabled ? Colors.white : Colors.grey),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: enabled ? Colors.white : Colors.grey)),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12002F), 
      body: Consumer<MovieDetailProvider>(
        builder: (context, provider, child) {
          final isLoading = provider.isLoading(widget.movieId);
          final error = provider.getError(widget.movieId);
          final movie = provider.getMovie(widget.movieId);

          if (isLoading && movie == null) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent));
          }

          if (error != null && movie == null) {
            return Center(
                child:
                    Text(error, style: const TextStyle(color: Colors.white)));
          }

          if (movie == null) {
            return const Center(
                child: Text('Movie not found',
                    style: TextStyle(color: Colors.white)));
          }

          final director = _findCrewMember(movie.crew, 'Director');
          final screenplay = _findCrewMember(movie.crew, 'Screenplay');
          final producer = _findCrewMember(movie.crew, 'Producer');

          return FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () {
                final authProvider = context.read<AuthProvider>();
                return context.read<MovieDetailProvider>().fetchMovieDetails(widget.movieId,
                    forceRefresh: true, currentUser: authProvider.currentUser);
              },
              color: Colors.pinkAccent,
              backgroundColor: const Color(0xFF1D0B3C),
              child: CustomScrollView(
                controller: _scrollController, 
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 480,
                    backgroundColor: const Color(0xFF12002F),
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
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          color: const Color(0xFF251043).withOpacity(0.95),
                          elevation: 10,
                          offset: const Offset(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                          ),
                          onSelected: (value) {
                            if (value == 'download') {
                              _handleDownloadTap(context, context.read<DownloadsProvider>().getStatus(movie.id), movie);
                            } else if (value == 'toggle_watchlist') {
                              final watchlistProvider = context.read<WatchlistProvider>();
                              final isInWatchlist = watchlistProvider.isInWatchlist(movie.id);
                              watchlistProvider.toggleWatchlist(movie);
                              ScaffoldMessenger.of(context).showSnackBar(
                                isInWatchlist
                                    ? _buildCustomSnackBar(Icons.remove_circle_outline, Colors.redAccent, 'Removed "${movie.title}" from your watchlist.')
                                    : _buildCustomSnackBar(Icons.check_circle, Colors.green, 'Added "${movie.title}" to your watchlist.'),
                              );
                            } else if (value == 'share') {
                              _shareMovie(context, movie);
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            final isInWatchlist = context.read<WatchlistProvider>().isInWatchlist(movie.id);
                            final downloadStatus = context.read<DownloadsProvider>().getStatus(movie.id);
                            final isDownloaded = downloadStatus == DownloadStatus.Downloaded;

                            return <PopupMenuEntry<String>>[
                              _buildPopupMenuItem(Icons.download_rounded, 'Download', 'download', enabled: !isDownloaded),
                              _buildPopupMenuItem(isInWatchlist ? Icons.bookmark_remove_rounded : Icons.bookmark_add_outlined,
                                  isInWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist', 'toggle_watchlist'),
                              _buildPopupMenuItem(Icons.share_rounded, 'Share', 'share'),
                            ];
                          },
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: widget.heroTag ?? 'movie_${movie.id}',
                            child: CachedNetworkImage(
                              imageUrl: movie.backdropPath != null
                                  ? '${ApiConstants.imageBaseUrlOriginal}${movie.backdropPath}'
                                  : (movie.posterPath != null ? '${ApiConstants.imageBaseUrlOriginal}${movie.posterPath}' : ''),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ), 
                          ), 
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF12002F).withOpacity(0.2),
                                  const Color(0xFF12002F).withOpacity(0.9),
                                  const Color(0xFF12002F),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.4, 0.6, 0.85, 1.0],
                              ),
                            ),
                          ),

                          _buildCenterPlayButtonOrProgress(context, movie),

                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Text(
                                    movie.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      fontFamily:
                                          'Roboto', 
                                      shadows: [
                                        Shadow(
                                            blurRadius: 10, color: Colors.black)
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (movie.genres != null &&
                                        movie.genres!.isNotEmpty) ...[
                                      _buildTag(
                                          movie.genres!.first.name,
                                          const Color(
                                              0xFF00ACC1)), 
                                      const SizedBox(width: 10),
                                    ],
                                    if (movie.runtime != null) ...[
                                      _buildTag(
                                          _formatRuntimeLikeImage(
                                              movie.runtime),
                                          const Color(0xFF9C27B0)), 
                                      const SizedBox(width: 10),
                                    ],
                                    _buildTag(
                                        '${movie.voteAverage.toStringAsFixed(1)} ★',
                                        const Color(0xFFE91E63)), 
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter( 
                    child: Padding(
                  padding: 
                      const EdgeInsets.fromLTRB(20, 5, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCrewSection(director, screenplay, producer),

                          const SizedBox(height: 20),

                          Text(
                            movie.overview,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                              height: 1.5,
                            ),
                            maxLines: _isOverviewExpanded ? null : 4,
                            overflow: _isOverviewExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                          GestureDetector(
                            onTap: () => setState(() =>
                                _isOverviewExpanded = !_isOverviewExpanded),
                            child: Text(
                              _isOverviewExpanded ? "View Less" : "View More",
                              style: const TextStyle(
                                  color: Colors.pinkAccent,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),

                          const SizedBox(height: 20),

                          _buildKeywordsSection(movie.keywords),
                          
                          SectionHeader(
                            title: "Cast",
                            accentColors: const [Color(0xFF40C9FF), Color(0xFFE81CFF)], 
                            onSeeAll: () => _seeAllCast(context, movie.cast),
                          ),
                          const SizedBox(height: 15),
                          if (movie.cast != null) _buildCastList(movie.cast!),
                          const SizedBox(height: 16),

                          if (movie.videos != null &&
                              movie.videos!.isNotEmpty) ...[
                            const SectionHeader(
                              title: "Trailers",
                              accentColors: [Color(0xFFFF006E), Color(0xFFFF6EC7)], 
                            ),
                            const SizedBox(height: 15),
                            _buildTrailersList(movie.videos!),
                            const SizedBox(height: 16),
                          ],
                          if (movie.recommendations != null &&
                              movie.recommendations!.isNotEmpty) ...[
                            SectionHeader(
                              title: "Related Movies",
                              accentColors: const [Color(0xFFFFD700), Color(0xFFFF8F00)], 
                              onSeeAll: () => _seeAllRelated(context, movie.recommendations),
                            ),
                            const SizedBox(height: 15),
                            _buildRelatedSection(movie.recommendations!),
                          const SizedBox(height: 16),
                          ],

                          _LazyReviewsSection(
                            movieId: movie.id,
                            movieTitle: movie.title,
                            myReviewKey: _myReviewKey,
                            scrollToMyReview: widget.scrollToMyReview,
                          ),

                          const SizedBox(height: 40), 
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

  void _showWriteReviewDialog(BuildContext context, int movieId, {Review? existingReview}) {
    final provider = context.read<MovieDetailProvider>();
    final ratingController = ValueNotifier<double>(existingReview?.rating ?? 5.0);
    final textController = TextEditingController();
    if (existingReview != null) {
      textController.text = existingReview.content;
    }
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF251043).withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: Text(
          existingReview != null ? 'Edit Your Review' : 'Write Your Review',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: ratingController,
                  builder: (context, value, child) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Your Rating:', style: TextStyle(color: Colors.white70)),
                            Text(
                              value.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: value,
                          min: 0.0,
                          max: 10.0,
                          divisions: 20, 
                          activeColor: Colors.pinkAccent,
                          inactiveColor: Colors.white30,
                          label: value.toStringAsFixed(1),
                          onChanged: (newValue) {
                            ratingController.value = newValue;
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: textController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please write something for your review.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final authProvider = context.read<AuthProvider>();
                await provider.saveUserReview(movieId, ratingController.value, textController.text, currentUser: authProvider.currentUser);
                await provider.fetchMovieReviews(movieId, forceRefresh: true, currentUser: authProvider.currentUser);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  _buildCustomSnackBar(
                    Icons.check_circle,
                    Colors.green,
                    existingReview != null ? 'Your review has been updated!' : 'Your review has been saved!',
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            child: Text(existingReview != null ? 'Update' : 'Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleDeleteReview(BuildContext context, int movieId, String movieTitle) async {
    final confirm = await UIHelpers.showConfirmDialog(
      context,
      'Are you sure you want to delete your review for "$movieTitle"? This action cannot be undone.',
      title: 'Delete Review',
      confirmText: 'Delete',
    );

    if (confirm == true && mounted) {
      try {
        final authProvider = context.read<AuthProvider>();
        final provider = context.read<MovieDetailProvider>();
        
        print('Starting delete for movieId: $movieId, user: ${authProvider.currentUser?.name}');
        
        await provider.deleteUserReview(movieId, currentUser: authProvider.currentUser);

        await provider.fetchMovieReviews(movieId, forceRefresh: true, currentUser: authProvider.currentUser);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildCustomSnackBar(Icons.check_circle, Colors.green, 'Your review has been deleted.')
          );
        }
        print('Delete operation completed successfully');
      } catch (e, stackTrace) {
        print('Error deleting review: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildCustomSnackBar(Icons.error, Colors.red, 'Failed to delete review: $e')
          );
        }
      }
    }
  }

  SnackBar _buildCustomSnackBar(IconData icon, Color color, String message) {
    return SnackBar(
      backgroundColor: Colors.white,
      content: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _seeAllCast(BuildContext context, List<Cast>? cast) { 
    if (cast == null || cast.isEmpty) return;
    context.push('/see-all', extra: {'title': 'Full Cast', 'cast': cast});
  }

  void _seeAllRelated(BuildContext context, List<Movie>? movies) {
    if (movies == null || movies.isEmpty) return;
    context.push('/see-all', extra: {'title': 'Related Movies', 'movies': movies});
  }

  Widget _buildCrewSection(
      String director, String screenplay, String producer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCrewItem("Director", director),
        _buildCrewItem("Screenplay", screenplay),
        _buildCrewItem("Production", producer),
      ],
    );
  }

  Widget _buildCrewItem(String title, String name) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCastList(List<Cast> cast) {
    return SizedBox(
      height: 110, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cast.length > 10 ? 10 : cast.length,
        itemBuilder: (context, index) {
          final actor = cast[index];
          return Container(
            width: 70,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: actor.profilePath != null
                          ? CachedNetworkImageProvider(
                              '${ApiConstants.imageBaseUrl}${actor.profilePath}')
                          : const AssetImage(
                                  'assets/images/placeholder_cast.png')
                              as ImageProvider, 
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  actor.name,
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.2),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrailersList(List<Video> videos) {
    final youtubeVideos =
        videos.where((v) => v.site.toLowerCase() == 'youtube').toList();

    if (youtubeVideos.isEmpty) return const SizedBox.shrink();

    final bool hasMore = youtubeVideos.length > 3;
    final List<Video> displayedVideos = _showAllTrailers || !hasMore
        ? youtubeVideos
        : youtubeVideos.take(3).toList();

    return Column(
      children: [
        ...displayedVideos.map((video) {
          return Padding(
            padding: const EdgeInsets.only(
                bottom: 8.0), 
            child: TrailerCard(video: video),
          );
        }),

        if (hasMore)
          Padding(
            padding:
                const EdgeInsets.only(top: 0), 
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllTrailers = !_showAllTrailers;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero, 
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _showAllTrailers ? 'Show Less' : 'Show More',
                style: const TextStyle(
                    color: Colors.pinkAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildActionButtonsRow(Movie movie) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Consumer<DownloadsProvider>(
            builder: (_, downloads, __) {
              final status = downloads.getStatus(movie.id);
              return _buildCustomActionButton(
                  icon: Icons.download_rounded,
                  label: "Download",
                  color: const Color(0xFF2C1A4C), 
                  onTap: () => _handleDownloadTap(context, status, movie));
            },
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Consumer<WatchlistProvider>(
            builder: (_, watchlist, __) {
              final isIn = watchlist.isInWatchlist(movie.id);
              return _buildCustomActionButton(
                  icon: isIn ? Icons.bookmark : Icons.bookmark_border,
                  label: "Watchlist",
                  color: const Color(0xFF2C1A4C),
                  isActive: isIn,
                  onTap: () => watchlist.toggleWatchlist(movie));
            },
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: _buildCustomActionButton(
              icon: Icons.share_rounded,
              label: "Share",
              color: const Color(0xFF2C1A4C),
              onTap: () => _shareMovie(context, movie)),
        ),
      ],
    );
  }

  Widget _buildCustomActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: () {
        FeedbackService.lightImpact(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.pinkAccent : color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedSection(List<Movie> movies) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[Colors.white.withOpacity(0.0), Colors.white, Colors.white, Colors.white.withOpacity(0.0)],
          stops: const [0.0, 0.05, 0.95, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        height: 250, 
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: movies.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CinematicWideCard(
              movie: movies[index],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFactsSection(Movie movie) {
    final numberFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildFactRow('Status', movie.status),
          _buildFactRow('Original Language', movie.originalLanguage),
          _buildFactRow('Budget', movie.budget != null && movie.budget! > 0 ? numberFormat.format(movie.budget) : null),
          _buildFactRow('Revenue', movie.revenue != null && movie.revenue! > 0 ? numberFormat.format(movie.revenue) : null),
          _buildFactRow('Production Companies', movie.productionCompanies?.join(', ')),
          _buildFactRow('Production Countries', movie.productionCountries?.join(', '), isLast: true),
        ],
      ),
    );
  }

  Widget _buildFactRow(String label, String? value, {bool isLast = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
      ],
    );
  }

  Widget _buildKeywordsSection(List<Keyword>? keywords) {
    if (keywords == null || keywords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Keywords",
          accentColors: [Colors.orangeAccent, Colors.deepOrangeAccent],
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: keywords.map((keyword) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepOrangeAccent.withOpacity(0.2),
                    Colors.orangeAccent.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.orangeAccent.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrangeAccent.withOpacity(0.1),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Text(
                '# ${keyword.name}', 
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }


  Widget _buildCenterPlayButtonOrProgress(BuildContext context, Movie movie) {
    final downloadsProvider = context.watch<DownloadsProvider>();
    final status = downloadsProvider.getStatus(movie.id);
    final progress = downloadsProvider.getProgress(movie.id);

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildWidgetForStatus(context, status, movie, progress),
      ),
    );
  }

  Widget _buildWidgetForStatus(BuildContext context, DownloadStatus status,
      Movie movie, double progress) {
    switch (status) {
      case DownloadStatus.Downloading:
      case DownloadStatus.Paused:
        return GestureDetector(
          onTap: () {
            final provider = context.read<DownloadsProvider>();
            if (status == DownloadStatus.Downloading) {
              provider.pauseDownload(movie.id);
            } else {
              provider.resumeDownload(movie);
            }
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.black54),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                    value: progress, color: Colors.pinkAccent),
                Icon(
                    status == DownloadStatus.Downloading
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white),
              ],
            ),
          ),
        );
      default:
        return GestureDetector(
          onTap: () {
            FeedbackService.playSound(context);
            _playTrailer(context, movie.trailerKey);
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.pinkAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 35),
          ),
        );
    }
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
            color: Color(0xFF1D0B3C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Select Quality',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ),
              ListTile(
                leading:
                    const Icon(Icons.high_quality, color: Colors.pinkAccent),
                title: const Text('High Quality',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  provider.downloadMovie(movie, DownloadQuality.high);
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.hd, color: Colors.purpleAccent),
                title: const Text('Medium Quality',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  provider.downloadMovie(movie, DownloadQuality.medium);
                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _shareMovie(BuildContext context, Movie movie) {
    final movieUrl = 'https://www.themoviedb.org/movie/${movie.id}';
    final shareText = 'Check out this movie: ${movie.title}!\n\n$movieUrl';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sharing: $shareText')));
  }

}

class _LazyReviewsSection extends StatefulWidget {
  final int movieId;
  final String movieTitle;
  final GlobalKey myReviewKey;
  final bool scrollToMyReview;

  const _LazyReviewsSection({
    required this.movieId,
    required this.movieTitle,
    required this.myReviewKey,
    required this.scrollToMyReview,
  });

  @override
  State<_LazyReviewsSection> createState() => _LazyReviewsSectionState();
}

class _LazyReviewsSectionState extends State<_LazyReviewsSection> {
  void _fetchReviews() {
    final provider = context.read<MovieDetailProvider>();
    if (!provider.haveReviewsBeenFetched(widget.movieId)) {
      final authProvider = context.read<AuthProvider>();
      provider.fetchMovieReviews(widget.movieId, currentUser: authProvider.currentUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('reviews-section-${widget.movieId}'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.1) {
          _fetchReviews();
        }
      },
      child: Consumer<MovieDetailProvider>(
        builder: (context, provider, child) {
          final isReviewsLoading = provider.isReviewsLoading(widget.movieId);
          final apiReviews = provider.getReviews(widget.movieId);
          final userReview = provider.getUserReview(widget.movieId);

          final List<Review> allReviews = [];
          if (userReview != null) {
            allReviews.add(userReview);
          }
          allReviews.addAll(apiReviews.where((apiReview) => apiReview.author != userReview?.author));

          if (isReviewsLoading && allReviews.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            ));
          }

          if (allReviews.isEmpty) {
            return _buildWriteReviewBox();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: "User Reviews",
                accentColors: const [Color(0xFF69F0AE), Color(0xFF00E676)],
                onSeeAll: allReviews.isNotEmpty
                    ? () => context.push('/see-all-reviews', extra: {
                          'title': 'Reviews for ${widget.movieTitle}',
                          'reviews': allReviews,
                        })
                    : null,
              ),
              const SizedBox(height: 15),
              _buildReviewList(allReviews),
              if (userReview == null) _buildWriteReviewBox(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWriteReviewBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Write a review",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        AddReviewBox(movieId: widget.movieId),
      ],
    );
  }

  Widget _buildReviewList(List<Review> allReviews) {
    final displayedReviews = allReviews.take(5).toList();
    final currentUser = context.read<AuthProvider>().currentUser;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: displayedReviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final review = displayedReviews[index];
        final isMyReview = review.author == 'You' || review.author == currentUser?.name;
        return ReviewItem(
          key: isMyReview ? widget.myReviewKey : null,
          review: review,
          isMyReview: isMyReview,
          movieId: widget.movieId,
          highlightOnLoad: isMyReview && widget.scrollToMyReview,
          onEdit: isMyReview ? () => (context.findAncestorStateOfType<_MovieDetailScreenState>())?._showWriteReviewDialog(context, widget.movieId, existingReview: review) : null,
          onDelete: isMyReview ? () => (context.findAncestorStateOfType<_MovieDetailScreenState>())?._handleDeleteReview(context, widget.movieId, widget.movieTitle) : null,
        );
      },
    );
  }
}

class ReviewItem extends StatefulWidget {
  final Review review;
  final bool isMyReview;
  final int movieId; 
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool highlightOnLoad;

  const ReviewItem({
    super.key,
    required this.review,
    required this.movieId,
    this.isMyReview = false,
    this.onEdit,
    this.onDelete,
    this.highlightOnLoad = false,
  });

  @override
  State<ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<ReviewItem> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isReplying = false; 
  final TextEditingController _replyController = TextEditingController();
  late AnimationController _highlightController;
  late Animation<Color?> _borderColorAnimation;
  int _refreshKey = 0; 

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), 
    );

    _borderColorAnimation = ColorTween(
      begin: Colors.pinkAccent.withOpacity(0.8), 
      end: Colors.white.withOpacity(0.1),       
    ).animate(CurvedAnimation(parent: _highlightController, curve: Curves.easeOut));

    if (widget.highlightOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _highlightController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movie = context.select((MovieDetailProvider p) => p.getMovie(widget.movieId));
    final review = widget.review;
    String formattedDate = '';
    if (review.createdAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(review.createdAt);
        formattedDate = DateFormat.yMMMMd().format(dateTime); 
      } catch (e) {
      }
    }

    return AnimatedBuilder(
      animation: _highlightController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.highlightOnLoad ? _borderColorAnimation.value ?? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.1),
              width: widget.highlightOnLoad ? 1.5 : 1.0, 
            ),
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white10,
                backgroundImage: review.fullAvatarUrl != null
                    ? CachedNetworkImageProvider(review.fullAvatarUrl!) as ImageProvider
                    : null,
                child: review.fullAvatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white54)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          review.author,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isMyReview) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                  if (formattedDate.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(formattedDate,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ]
                ]),
              ),
              if (widget.isMyReview)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      widget.onEdit?.call();
                    } else if (value == 'delete') {
                      widget.onDelete?.call();
                    }
                  },
                  icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                  color: const Color(0xFF2C1D4D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                          SizedBox(width: 12),
                          Text('Edit', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                )
              else
              if (review.rating != null)
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      review.rating!.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),

          AnimatedCrossFade(
            firstChild: Text(
              review.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            secondChild: Text(
              review.content,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Text(
                  _isExpanded ? "Show less" : "Read more",
                  style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isReplying = !_isReplying;
                  });
                },
                child: const Row(
                  children: [
                    Icon(Icons.reply, color: Colors.white54, size: 18),
                    SizedBox(width: 4),
                    Text(
                      "Reply",
                      style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          
          if (movie != null)
            FutureBuilder<List<Review>>(
              key: ValueKey(_refreshKey), 
              future: DatabaseHelper.instance.getReviewReplies(
                movie.id,
                widget.review.author,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return _buildRepliesList(snapshot.data!);
                }
                
                return const SizedBox.shrink();
              },
            ),

          if (_isReplying) ...[
            const SizedBox(height: 8),
            if (movie != null)
              _buildReplyInput(context, movie),
            if (movie == null)
              const SizedBox.shrink(),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyInput(BuildContext context, Movie movie) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final avatarUrl = currentUser?.profileImageUrl;
    
    ImageProvider? avatarImage;
    if (avatarUrl != null) {
      if (avatarUrl.startsWith('file://')) {
        final filePath = avatarUrl.replaceFirst('file://', '');
        avatarImage = FileImage(File(filePath));
      } else if (avatarUrl.startsWith('http')) {
        avatarImage = CachedNetworkImageProvider(avatarUrl);
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? const Icon(Icons.person, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _replyController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Write a reply...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.pinkAccent, size: 20),
                  onPressed: () async {
                    final replyText = _replyController.text.trim();
                    if (replyText.isEmpty) return;

                    // Clear input and close reply box immediately for better UX
                    _replyController.clear();
                    setState(() {
                      _isReplying = false;
                    });

                    await DatabaseHelper.instance.saveReviewReply(
                      movieId: movie.id,
                      parentReviewAuthor: widget.review.author,
                      replyContent: replyText,
                      replyAuthor: currentUser?.name ?? 'You',
                      replyAuthorAvatar: currentUser?.profileImageUrl,
                    );

                    // Send notification to the review author (not the replier)
                    if (!widget.isMyReview) {
                      final reviewAuthorUserId = await DatabaseHelper.instance
                          .getUserIdByReviewAuthor(movie.id, widget.review.author);
                      
                      if (reviewAuthorUserId != null) {
                        final notification = AppNotification(
                          id: 'reply_${movie.id}_${DateTime.now().millisecondsSinceEpoch}',
                          title: '💬 New Reply!',
                          body: '${currentUser?.name ?? 'Someone'} replied to your review on "${movie.title}".',
                          timestamp: DateTime.now(),
                          type: NotificationType.reply,
                          movieId: movie.id,
                        );
                        
                        await context.read<NotificationProvider>()
                            .addNotificationForUser(reviewAuthorUserId, notification);
                      }
                    }

                    // Force refresh the replies list
                    if (mounted) {
                      setState(() {
                        _refreshKey++;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesList(List<Review> replies) {
    final currentUser = context.read<AuthProvider>().currentUser;
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: replies.length,
      itemBuilder: (context, index) {
        final reply = replies[index];
        final avatarUrl = reply.fullAvatarUrl;
        final isMyReply = reply.author == currentUser?.name || reply.author == 'You';
        
        ImageProvider? avatarImage;
        if (avatarUrl != null) {
          if (avatarUrl.startsWith('file://')) {
            final filePath = avatarUrl.replaceFirst('file://', '');
            avatarImage = FileImage(File(filePath));
          } else if (avatarUrl.startsWith('http')) {
            avatarImage = CachedNetworkImageProvider(avatarUrl);
          }
        }
        
        return Container(
          margin: const EdgeInsets.only(top: 12, left: 20), 
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? const Icon(Icons.person, size: 16, color: Colors.white70)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          reply.author,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (isMyReply) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reply.content,
                      style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isMyReply && reply.replyId != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final confirm = await UIHelpers.showConfirmDialog(
                      context,
                      'Are you sure you want to delete this reply?',
                      title: 'Delete Reply',
                      confirmText: 'Delete',
                    );
                    if (confirm == true) {
                      await DatabaseHelper.instance.deleteReply(reply.replyId!);
                      setState(() {
                        _refreshKey++; 
                      });
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
