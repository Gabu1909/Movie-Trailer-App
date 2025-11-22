import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; 
import '../../../core/api/api_constants.dart';
import '../../../providers/movie_provider.dart'; 
import '../../../core/models/genre.dart';
import '../../../core/models/movie.dart';
import '../../providers/downloads_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/watchlist_provider.dart';
import 'my_list_see_all_screen.dart'; 
import '../../../core/services/feedback_service.dart'; 
import '../../../shared/utils/ui_helpers.dart';

enum SortOption { byName, byDateAdded }

enum FeaturedReason { none, highestRated, recentlyAdded }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedGenreId; 
  List<Genre> _availableGenres = [];
  SortOption _currentSortOption =
      SortOption.byDateAdded; 

  final GlobalKey<AnimatedListState> _downloadsListKey =
      GlobalKey<AnimatedListState>();
  List<Movie> _downloads = []; 

  DownloadsProvider? _downloadsProvider;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    final movieProvider = context.read<MovieProvider>();
    _downloadsProvider = context.read<DownloadsProvider>();

    _availableGenres = movieProvider.genres;

    _downloads = List.from(_downloadsProvider!.downloadedMovies);
    _downloads = _sortMovies(
        List.from(_downloadsProvider!.downloadedMovies)); 
    _downloadsProvider!.addListener(_onDownloadsChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _downloadsProvider
        ?.removeListener(_onDownloadsChanged); 
    super.dispose();
  }

  void _onDownloadsChanged() {
    final newDownloads = context.read<DownloadsProvider>().downloadedMovies;
    if (!mounted) return; 

    final sortedNewDownloads =
        _sortMovies(newDownloads); 

    final List<Movie> removedMovies = _downloads
        .where((movie) =>
            !sortedNewDownloads.any((newMovie) => newMovie.id == movie.id))
        .toList();

    for (final movie in removedMovies) {
      final index = _downloads.indexWhere((m) => m.id == movie.id);
      if (index != -1) {
        final removedMovie = _downloads[index];
        _downloads.removeAt(index);
        _downloadsListKey.currentState?.removeItem(
          index,
          (context, animation) => _buildDownloadItemWithAnimation(
            context,
            removedMovie,
            context.read<DownloadsProvider>(),
            animation,
            index,
          ),
          duration: const Duration(milliseconds: 500),
        );
      }
    }

    final List<Movie> addedMovies = sortedNewDownloads
        .where(
            (movie) => !_downloads.any((oldMovie) => oldMovie.id == movie.id))
        .toList();

    for (final movie in addedMovies) {
      int insertionIndex = 0;
      while (insertionIndex < _downloads.length &&
          _sortMovies([_downloads[insertionIndex], movie]).first.id !=
              movie.id) {
        insertionIndex++;
      }

      _downloads.insert(insertionIndex, movie); 
      _downloadsListKey.currentState?.insertItem(
        insertionIndex,
        duration: const Duration(milliseconds: 500),
      );
    }

    setState(() {
      _downloads = _sortMovies(List.from(_downloads));
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear(); 
      _selectedGenreId = null;
    });
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      context
          .read<DownloadsProvider>()
          .loadDownloadedMovies(), 
      context.read<FavoritesProvider>().loadFavorites(),
      context.read<WatchlistProvider>().loadWatchlist(),
    ]);

    if (mounted) {
      UIHelpers.showSuccessSnackBar(
          context, 'Lists have been updated successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    _availableGenres = context.watch<MovieProvider>().genres;

    List<Movie> originalDownloads =
        context.watch<DownloadsProvider>().downloadedMovies;
    List<Movie> originalFavorites =
        context.watch<FavoritesProvider>().favorites;
    List<Movie> originalWatchlist =
        context.watch<WatchlistProvider>().watchlistMovies;

    List<Movie> allDownloads = _sortMovies(originalDownloads);
    List<Movie> allFavorites = _sortMovies(originalFavorites);
    List<Movie> allWatchlist = _sortMovies(originalWatchlist);

    final List<Movie> searchFilteredDownloads = _searchQuery.isEmpty
        ? allDownloads
        : allDownloads
            .where((movie) =>
                movie.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
    final List<Movie> searchFilteredFavorites = _searchQuery.isEmpty
        ? allFavorites
        : allFavorites
            .where((movie) =>
                movie.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
    final List<Movie> searchFilteredWatchlist = _searchQuery.isEmpty
        ? allWatchlist
        : allWatchlist
            .where((m) =>
                m.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    List<Movie> filteredDownloads =
        _filterMoviesByGenre(searchFilteredDownloads);
    List<Movie> filteredFavorites =
        _filterMoviesByGenre(searchFilteredFavorites);
    List<Movie> filteredWatchlist =
        _filterMoviesByGenre(searchFilteredWatchlist);

    final allCombinedItems = [
      ...originalDownloads,
      ...originalFavorites,
      ...originalWatchlist,
    ];

    Movie? featuredMovie;
    FeaturedReason reason = FeaturedReason.none;

    if (_searchQuery.isEmpty &&
        _selectedGenreId == null &&
        allCombinedItems.isNotEmpty) {
      final List<Movie> recentlyAddedSorted = List.from(allCombinedItems)
        ..sort((a, b) {
          if (a.dateAdded == null) return 1;
          if (b.dateAdded == null) return -1;
          return b.dateAdded!.compareTo(a.dateAdded!);
        });
      final Movie? mostRecent =
          recentlyAddedSorted.isNotEmpty ? recentlyAddedSorted.first : null;

      final List<Movie> highestRatedSorted = List.from(allCombinedItems)
        ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
      featuredMovie = highestRatedSorted.first;

      if (mostRecent != null && featuredMovie.id == mostRecent.id) {
        reason = FeaturedReason.recentlyAdded;
      } else {
        reason = FeaturedReason.highestRated;
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B124C), Color(0xFF5B2A9B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'My List',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 16), 
                        Flexible(child: _buildSearchAndFilterBar(context)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Colors.white24),
                    _buildClearFiltersButton(),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: Colors.pinkAccent, 
                  backgroundColor:
                      const Color(0xFF3A0CA3), 
                  child: ListView(
                    padding: const EdgeInsets.only(top: 16, bottom: 40),
                    children: [
                      if (featuredMovie !=
                          null) 
                        _buildFeaturedMovie(context, featuredMovie, reason),
                      if (_searchQuery.isEmpty && _selectedGenreId == null)
                        const SizedBox(height: 20),
                      if (filteredDownloads.isNotEmpty) ...[
                        _buildDownloadsSection(context, filteredDownloads),
                        const SizedBox(height: 20),
                      ],
                      _buildFavoritesSection(
                          context, filteredFavorites, "All Favorites"),
                      const SizedBox(height: 20),
                      _buildWatchlistSection(
                          context, filteredWatchlist, "Full Watchlist"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Movie> _sortMovies(List<Movie> movies) {
    List<Movie> sortedList = List.from(movies);
    switch (_currentSortOption) {
      case SortOption.byName:
        sortedList.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.byDateAdded:
        sortedList.sort((a, b) {
          if (a.dateAdded == null || b.dateAdded == null) return 0;
          return b.dateAdded!.compareTo(a.dateAdded!);
        });
    }
    return sortedList;
  }

  void _goToMovieDetail(BuildContext context, Movie movie) {
    if (movie.mediaType == 'tv') {
      context.push(
        '/tv/${movie.id}',
        extra: {'heroTag': 'favorites-tv-${movie.id}'},
      );
    } else {
      context.push(
        '/movie/${movie.id}',
        extra: {'heroTag': 'favorites-${movie.id}'},
      );
    }
  }

  void _shareMovie(BuildContext context, Movie movie) {
    FeedbackService.playSound(context);
    FeedbackService.lightImpact(context);

    UIHelpers.showInfoSnackBar(context, 'Share feature temporarily disabled');
  }

  void _playTrailer(BuildContext context, String? trailerKey) {
    if (trailerKey == null || trailerKey.isEmpty) {
      UIHelpers.showWarningSnackBar(
          context, 'Trailer not available for this movie');
      return;
    }

    context.push(
      '/play-youtube/$trailerKey',
      extra: {'title': 'Trailer'},
    );
  }

  String _getGenreNames(Movie movie) {
    if (movie.genres?.isEmpty ?? true) return '';
    final genreNames = movie.genres!
        .map((g) => _availableGenres
            .firstWhere(
              (ag) => ag.id == g.id,
              orElse: () => Genre(id: 0, name: ''),
            )
            .name)
        .where((name) => name.isNotEmpty)
        .toList();
    return genreNames.join(', ');
  }

  String _formatRuntimeOnly(int? runtime) {
    if (runtime == null || runtime == 0) return '';
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    if (minutes > 0) return '${minutes}m';
    return '';
  }

  Widget _buildHeroActionButton(IconData icon, String label,
      {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedMovie(
      BuildContext context, Movie movie, FeaturedReason reason) {
    String featuredLabel = '';
    IconData featuredIcon = Icons.info;

    switch (reason) {
      case FeaturedReason.highestRated:
        featuredLabel = 'Highest Rated';
        featuredIcon = Icons.star;
        break;
      case FeaturedReason.recentlyAdded:
        featuredLabel = 'Recently Added';
        featuredIcon = Icons.new_releases;
        break;
      case FeaturedReason.none:
        break;
    }

    return GestureDetector(
      onTap: () => _goToMovieDetail(context, movie),
      child: Container(
        height: 400, 
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl:
                    '${ApiConstants.imageBaseUrlOriginal}${movie.posterPath}',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0), 
                      Colors.black.withOpacity(0.2), 
                      Colors.black.withOpacity(0.8), 
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        fontSize: 26, 
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (reason != FeaturedReason.none) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(featuredIcon,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(featuredLabel,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRatingStars(movie.voteAverage),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '${movie.releaseDate?.year ?? ''} • ${_getGenreNames(movie)}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_formatRuntimeOnly(movie.runtime).isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Text(
                            _formatRuntimeOnly(movie.runtime),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      movie.overview,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildHeroActionButton(Icons.play_arrow, 'Play',
                            onTap: () => _goToMovieDetail(context, movie)),
                        const SizedBox(width: 10),
                        _buildHeroActionButton(Icons.info_outline, 'Info',
                            onTap: () => _goToMovieDetail(context, movie)),
                        const SizedBox(width: 10),
                        _buildHeroActionButton(Icons.share, 'Share',
                            onTap: () => _shareMovie(context, movie)),
                        const SizedBox(width: 10),
                        _buildHeroActionButton(
                            Icons.delete_outline, 'Remove', 
                            onTap: () =>
                                _removeMovieFromAllLists(context, movie)),
                      ], 
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog({
    required Movie movie,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, 
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF3A0CA3), 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side:
              BorderSide(color: Colors.white.withOpacity(0.2)), 
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 12),
            Text('Confirm Deletion'),
          ],
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        content: Text(
          content,
          style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop(); 
              onConfirm(); 
              UIHelpers.showSuccessSnackBar(
                context,
                '"${movie.title}" has been removed.',
              );
            },
          ),
        ],
      ),
    );
  }

  void _removeMovieFromAllLists(BuildContext context, Movie movie) {
    FeedbackService.playSound(context);
    FeedbackService.lightImpact(context);
    _showDeleteConfirmationDialog(
        movie: movie,
        content:
            'Are you sure you want to remove "${movie.title}" from all your lists (Favorites, Watchlist, Downloads)?',
        onConfirm: () {
          SystemSound.play(SystemSoundType.click); 
          context.read<FavoritesProvider>().removeFavorite(movie.id);
          context.read<WatchlistProvider>().removeWatchlist(movie.id);
          context.read<DownloadsProvider>().removeDownload(movie);
        });
  }

  Widget _buildDownloadsSection(
      BuildContext context, List<Movie> filteredDownloads) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Text(
                'DOWNLOADS (Movies only)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  FeedbackService.playSound(context);
                  FeedbackService.lightImpact(context);
                  context.push(
                    '/my-list/see-all',
                    extra: {
                      'title': 'All Downloads',
                      'listType': MyListType.downloads,
                    },
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final slideAnimation = Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation);
              return SlideTransition(position: slideAnimation, child: child);
            },
            child: filteredDownloads.isEmpty
                ? _buildEmptyState(
                    key: const ValueKey('empty_downloads_animated'),
                    icon: Icons.cloud_off_outlined,
                    message: 'Movies you download will appear here.',
                  )
                : ListView.builder(
                    key: const ValueKey('downloads_list'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredDownloads.length,
                    itemBuilder: (context, index) {
                      final movie = filteredDownloads[index];
                      return _buildDownloadItem(
                        context,
                        movie,
                        context.read<DownloadsProvider>(),
                        key: ValueKey('download_${movie.id}_$index'),
                      );
                    },
                  ),
          ), 
        ],
      ),
    );
  }

  Widget _buildDownloadItem(
      BuildContext context, Movie movie, DownloadsProvider provider,
      {Key? key}) {
    return _buildDownloadItemWithAnimation(context, movie, provider, null, null,
        key: key); 
  }

  Widget _buildDownloadItemWithAnimation(BuildContext context, Movie movie,
      DownloadsProvider provider, Animation<double>? animation, int? index,
      {Key? key}) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int memCacheWidth = (60 * devicePixelRatio).round();
    final int memCacheHeight = (90 * devicePixelRatio).round();
    final itemContent = Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: '${ApiConstants.imageBaseUrl}${movie.posterPath}',
            width: 60,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          movie.title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${_getGenreNames(movie)} ${_formatRuntimeOnly(movie.runtime).isNotEmpty ? '• ${_formatRuntimeOnly(movie.runtime)}' : ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            _buildRatingStars(movie.voteAverage),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.play_circle_fill, color: Colors.pinkAccent),
              tooltip: 'Play Trailer (or Downloaded Video if offline)',
              onPressed: () async {
                FeedbackService.playSound(context);
                FeedbackService.lightImpact(context);

                print(
                    'Download play button pressed for: ${movie.title} (ID: ${movie.id})');
                print('TrailerKey from database: ${movie.trailerKey}');

                if (movie.trailerKey != null && movie.trailerKey!.isNotEmpty) {
                  print('Playing YouTube trailer: ${movie.trailerKey}');
                  _playTrailer(context, movie.trailerKey);
                } else {
                  print('No trailerKey found, trying local video...');
                  final filePath = provider.getFilePath(movie.id);
                  if (filePath != null) {
                    print('Playing local file: $filePath');
                    context.push('/play-local/${movie.id}',
                        extra: {'filePath': filePath, 'title': movie.title});
                  } else {
                    print('No local file found either');
                    UIHelpers.showWarningSnackBar(
                      context,
                      'No trailer or downloaded video available',
                    );
                  }
                }
              },
            ),

            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Remove Download',
              onPressed: () {
                FeedbackService.playSound(context);
                FeedbackService.lightImpact(context);
                _showDeleteConfirmationDialog(
                  movie: movie,
                  content: 'Are you sure you want to remove this download?',
                  onConfirm: () {
                    SystemSound.play(SystemSoundType.click);
                    provider.removeDownload(movie);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );

    return animation != null
        ? SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0), 
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: itemContent,
            ),
          )
        : itemContent; 
  }

  Widget _buildFavoritesSection(
      BuildContext context, List<Movie> favorites, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Text(
                'Favorites', 
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  FeedbackService.playSound(context);
                  FeedbackService.lightImpact(context);
                  context.push(
                    '/my-list/see-all',
                    extra: {
                      'title': title, 
                      'listType': MyListType.favorites,
                    },
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(position: slideAnimation, child: child);
              },
              child: favorites.isEmpty
                  ? _buildEmptyState(
                      key: const ValueKey('empty_favorites'),
                      icon: Icons.favorite_border,
                      message: 'Your favorite movies will be stored here.',
                    )
                  : Column(
                      key: const ValueKey('filled_favorites'),
                      children: favorites.map((movie) {
                        return _buildFavoriteItem(
                            context, movie, context.read<FavoritesProvider>());
                      }).toList(),
                    )),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(
      BuildContext context, Movie movie, FavoritesProvider provider) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int memCacheWidth = (60 * devicePixelRatio).round();
    final int memCacheHeight = (90 * devicePixelRatio).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () {
          if (movie.mediaType == 'tv') {
            context.push(
              '/tv/${movie.id}',
              extra: {'heroTag': 'favorites-list-tv-${movie.id}'},
            );
          } else {
            context.push(
              '/movie/${movie.id}',
              extra: {'heroTag': 'favorites-list-${movie.id}'},
            );
          }
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: '${ApiConstants.imageBaseUrl}${movie.posterPath}',
            width: 60,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          movie.title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${_getGenreNames(movie)} ${_formatRuntimeOnly(movie.runtime).isNotEmpty ? '• ${_formatRuntimeOnly(movie.runtime)}' : ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            _buildRatingStars(movie.voteAverage),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
          onPressed: () {
            FeedbackService.playSound(context);
            FeedbackService.lightImpact(context);
            _showDeleteConfirmationDialog(
              movie: movie,
              content:
                  'Are you sure you want to remove "${movie.title}" from your favorites?',
              onConfirm: () {
                SystemSound.play(
                    SystemSoundType.click); 
                provider.toggleFavorite(movie);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWatchlistSection(
      BuildContext context, List<Movie> watchlist, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Watchlist',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  FeedbackService.playSound(context);
                  FeedbackService.lightImpact(context);
                  context.push(
                    '/my-list/see-all',
                    extra: {
                      'title': title, 
                      'listType': MyListType.watchlist,
                    },
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final slideAnimation = Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation);
              return SlideTransition(position: slideAnimation, child: child);
            },
            child: watchlist.isEmpty
                ? _buildEmptyState(
                    key: const ValueKey('empty_watchlist'),
                    icon: Icons.bookmark_border,
                    message: 'Add movies to your watchlist to see them here.',
                  )
                : Column(
                    key: const ValueKey('filled_watchlist'),
                    children: watchlist.map((movie) {
                      return _buildWatchlistItem(
                          context, movie, context.read<WatchlistProvider>());
                    }).toList(),
                  ),
          ), 
        ],
      ),
    );
  }

  Widget _buildWatchlistItem(
      BuildContext context, Movie movie, WatchlistProvider provider) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int memCacheWidth = (60 * devicePixelRatio).round();
    final int memCacheHeight = (90 * devicePixelRatio).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () {
          if (movie.mediaType == 'tv') {
            context.push(
              '/tv/${movie.id}',
              extra: {'heroTag': 'watchlist-tv-${movie.id}'},
            );
          } else {
            context.push(
              '/movie/${movie.id}',
              extra: {'heroTag': 'watchlist-${movie.id}'},
            );
          }
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: '${ApiConstants.imageBaseUrl}${movie.posterPath}',
            width: 60,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(movie.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
                '${_getGenreNames(movie)} ${_formatRuntimeOnly(movie.runtime).isNotEmpty ? '• ${_formatRuntimeOnly(movie.runtime)}' : ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            _buildRatingStars(movie.voteAverage),
          ],
        ),
        trailing: IconButton(
            icon: const Icon(Icons.bookmark_remove,
                color: Colors.pinkAccent), 
            onPressed: () {
              FeedbackService.playSound(context);
              FeedbackService.lightImpact(context);
              _showDeleteConfirmationDialog(
                movie: movie,
                content:
                    'Are you sure you want to remove "${movie.title}" from your watchlist?',
                onConfirm: () {
                  SystemSound.play(
                      SystemSoundType.click); 
                  provider.toggleWatchlist(movie);
                }, 
              );
            }),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, 
      children: [
        Flexible(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search your movies...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                    const BorderSide(color: Colors.pinkAccent, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white70),
            onPressed: () {
              FeedbackService.playSound(context);
              FeedbackService.lightImpact(context);
              _showFilterBottomSheet(context);
            },
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2B124C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)), 
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter & Sort',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  _buildGenreFilter(setModalState),
                  const SizedBox(height: 16),
                  _buildSortOptions(setModalState),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClearFiltersButton() {
    final bool isFilterActive =
        _searchQuery.isNotEmpty || _selectedGenreId != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: isFilterActive
          ? Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: TextButton.icon(
                  onPressed: () {
                    FeedbackService.playSound(context);
                    FeedbackService.lightImpact(context);
                    _clearFilters();
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear Filters'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildGenreFilter(StateSetter setModalState) {
    final List<Genre> displayGenres = [
      Genre(id: 0, name: 'All Genres'), 
      ..._availableGenres,
    ];

    return Container(
      height: 45, 
      margin: const EdgeInsets.only(top: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: displayGenres.map((genre) {
            final bool isSelected =
                (_selectedGenreId == null && genre.id == 0) ||
                    (_selectedGenreId == genre.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(genre.name),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    FeedbackService.playSound(context);
                    FeedbackService.lightImpact(context);
                    setModalState(() {
                      setState(() {
                        _selectedGenreId = (genre.id == 0) ? null : genre.id;
                      });
                    });
                  }
                },
                selectedColor: Colors.pinkAccent,
                backgroundColor: Colors.white.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.pinkAccent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSortOptions(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Sort by:", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSortChip('Date Added', SortOption.byDateAdded, setModalState),
            const SizedBox(width: 10),
            _buildSortChip('Name (A-Z)', SortOption.byName, setModalState),
          ],
        ),
      ],
    );
  }

  Widget _buildSortChip(
      String label, SortOption option, StateSetter setModalState) {
    final bool isSelected = _currentSortOption == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          FeedbackService.playSound(context);
          FeedbackService.lightImpact(context);
          setModalState(() {
            setState(() => _currentSortOption = option);
          });
        }
      },
      selectedColor: Colors.pinkAccent,
      backgroundColor: Colors.white.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.pinkAccent : Colors.transparent,
          width: 1.5,
        ),
      ),
    );
  }

  List<Movie> _filterMoviesByGenre(List<Movie> movies) {
    if (_selectedGenreId == null) return movies;
    return movies
        .where((movie) =>
            movie.genres?.any((g) => g.id == _selectedGenreId) ?? false)
        .toList();
  }

  Widget _buildRatingStars(double voteAverage) {
    final rating = voteAverage / 2; 
    final List<Widget> stars = List.generate(5, (index) {
      return Icon(
        index < rating.floor()
            ? Icons.star
            : index < rating
                ? Icons.star_half
                : Icons.star_border,
        color: Colors.amber,
        size: 16,
      );
    });

    stars.add(const SizedBox(width: 4));
    stars.add(Text(voteAverage.toStringAsFixed(1),
        style: const TextStyle(color: Colors.white70, fontSize: 12)));

    return Row(children: stars);
  }

  Widget _buildEmptyState(
      {Key? key, required IconData icon, required String message}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white54,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                FeedbackService.playSound(context);
                FeedbackService.lightImpact(context);
                context.go('/home');
              },
              icon: const Icon(Icons.add_to_photos_rounded),
              label: const Text('Find Movies to Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
