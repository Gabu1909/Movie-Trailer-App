import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../api/api_constants.dart';
import '../api/api_service.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import '../providers/favorites_provider.dart';
import '../providers/downloads_provider.dart';
import '../data/database_helper.dart';
import '../providers/watchlist_provider.dart';

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
  final _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _movieFuture = _fetchMovieDetails();
  }

  Future<Movie> _fetchMovieDetails() async {
    // First, get the movie details from the API
    final movieFromApi = await ApiService().getMovieDetail(widget.movieId);
    // Then, check the local DB for its favorite/watchlist status
    return _dbHelper.getMovieWithLocalStatus(movieFromApi);
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
      Navigator.of(context).push(
        // Sử dụng PageRouteBuilder để có hiệu ứng mờ dần (fade)
        PageRouteBuilder(
          opaque: false, // Cho phép nhìn thấy màn hình bên dưới
          pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
            backgroundColor: Colors.black.withOpacity(0.85), // Nền đen mờ
            body: Center(
              child: YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: trailerKey,
                  flags: const YoutubePlayerFlags(
                    autoPlay: true,
                    mute: false,
                    forceHD: true, // Cố gắng phát ở chất lượng HD
                  ),
                ),
                // Tùy chỉnh giao diện
                progressIndicatorColor:
                    Colors.pinkAccent, // Màu thanh tiến trình
                progressColors: const ProgressBarColors(
                  playedColor: Colors.pinkAccent,
                  handleColor: Colors.pinkAccent,
                ),
                onReady: () {
                  // Có thể làm gì đó khi trình phát đã sẵn sàng
                },
                // Thêm nút đóng
                bottomActions: [
                  CurrentPosition(),
                  ProgressBar(isExpanded: true),
                  RemainingDuration(),
                  const PlaybackSpeedButton(),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context.pop()),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No trailer available.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B124C),
      body: FutureBuilder<Movie>(
        future: _movieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent));
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData) {
            return const Center(
                child: Text('Movie not found',
                    style: TextStyle(color: Colors.white)));
          }

          final movie = snapshot.data!;
          final director = _findCrewMember(movie.crew, 'Director');
          final screenplay = _findCrewMember(movie.crew, 'Screenplay');
          final producer = _findCrewMember(movie.crew, 'Producer');

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 400,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, child) {
                      final isFavorite = favoritesProvider.isFavorite(movie.id);
                      // Lấy đúng đối tượng movie từ provider nếu nó đã được yêu thích,
                      // nếu không thì dùng đối tượng từ FutureBuilder.
                      // Điều này đảm bảo chúng ta có trạng thái isFavorite chính xác.
                      final movieForAction = isFavorite
                          ? favoritesProvider.favorites
                              .firstWhere((m) => m.id == movie.id)
                          : movie;
                      return IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.redAccent,
                        ),
                        onPressed: () async {
                          await favoritesProvider
                              .toggleFavorite(movieForAction);
                          setState(() {
                            _movieFuture = _fetchMovieDetails();
                          });
                        },
                      );
                    },
                  ),
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
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                            stops: [0.4, 1],
                          ),
                        ),
                      ),
                      Center(
                        child: GestureDetector(
                          onTap: () => _playTrailer(context, movie.trailerKey),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pinkAccent.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: const Icon(Icons.play_arrow,
                                color: Colors.white, size: 60),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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

              // ================= CONTENT =================
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF2B124C),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== Crew info =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCrewInfo('Director', director),
                          _buildCrewInfo('Screenplay', screenplay),
                          _buildCrewInfo('Production', producer),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ===== Overview with box =====
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.overview,
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.5,
                                fontSize: 14,
                              ),
                              maxLines: _isOverviewExpanded ? null : 4,
                              overflow: _isOverviewExpanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                            ),
                            if (movie.overview.length > 150)
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isOverviewExpanded = !_isOverviewExpanded;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _isOverviewExpanded
                                        ? 'View Less'
                                        : 'View More',
                                    style: const TextStyle(
                                      color: Colors.pinkAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ===== CAST =====
                      _buildHorizontalList('CAST', movie.cast),
                      const SizedBox(height: 24),

                      // ===== Action buttons (Moved here) =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDownloadButton(movie),
                          Consumer<WatchlistProvider>(
                            builder: (context, provider, child) {
                              final isInWatchlist =
                                  provider.isInWatchlist(movie.id);
                              return GestureDetector(
                                onTap: () async {
                                  await provider.toggleWatchlist(movie);
                                  // No need to refetch here, provider handles it.
                                },
                                child: _buildActionButton(
                                  isInWatchlist
                                      ? Icons.bookmark_added
                                      : Icons.bookmark_add_outlined,
                                  'Watchlist',
                                ),
                              );
                            },
                          ),
                          _buildActionButton(Icons.share, 'Share'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ===== RELATED =====
                      _buildHorizontalList(
                          'RELATED VIDEO', movie.recommendations),
                      const SizedBox(height: 32),
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

  // === Helper Widgets ===

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  Widget _buildCrewInfo(String title, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 3),
        Text(name,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  // Widget mới cho nút Download, có quản lý trạng thái
  Widget _buildDownloadButton(Movie movie) {
    return Consumer<DownloadsProvider>(
      builder: (context, provider, child) {
        final status = provider.getStatus(movie.id);
        final progress = provider.getProgress(movie.id);

        // Giả sử bạn có một link video giả
        const fakeVideoUrl =
            'https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4';

        switch (status) {
          case DownloadStatus.Downloading:
            return Column(
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
                      ),
                      Center(
                          child: Text('${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Downloading',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            );
          case DownloadStatus.Downloaded:
            return _buildActionButton(Icons.check_circle, 'Downloaded');
          case DownloadStatus.Error:
            return _buildActionButton(Icons.error, 'Error');
          default: // NotDownloaded
            return GestureDetector(
                onTap: () => provider.downloadMovie(movie, fakeVideoUrl),
                child: _buildActionButton(Icons.download, 'Download'));
        }
      },
    );
  }

  Widget _buildHorizontalList(String title, List<dynamic>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final isCast = title == 'CAST';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            GestureDetector(
              onTap: () {
                context.push('/see-all', extra: {
                  'title': title,
                  'movies': isCast ? null : items,
                  'cast': isCast ? items : null,
                });
              },
              child: Text('See All', style: TextStyle(color: Colors.grey[400])),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: isCast ? 120 : 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              if (isCast) {
                final cast = items[index] as Cast;
                return _buildCastCard(context, cast);
              } else {
                final movie = items[index] as Movie;
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 10),
                  child: MovieCard(movie: movie),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCastCard(BuildContext context, Cast cast) {
    return GestureDetector(
      onTap: () {
        context.push('/actor/${cast.id}');
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: cast.profilePath != null
                  ? CachedNetworkImageProvider(
                      '${ApiConstants.imageBaseUrl}${cast.profilePath}')
                  : null,
              child: cast.profilePath == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 6),
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
