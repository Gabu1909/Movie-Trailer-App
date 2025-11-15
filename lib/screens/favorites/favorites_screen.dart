import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
// import 'package:share_plus/share_plus.dart'; // Tạm comment để tránh lỗi
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // Thêm import để sử dụng SystemSound
import 'package:intl/intl.dart'; // Import for DateFormat
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // YouTube player
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Tạm comment
import '../../api/api_constants.dart';
import '../../providers/movie_provider.dart'; // Import MovieProvider
import '../../models/genre.dart';
import '../../models/movie.dart';
import '../../providers/downloads_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../providers/bottom_nav_visibility_provider.dart';
import 'my_list_see_all_screen.dart'; // Import the enum
import '../../widgets/navigation/scroll_hiding_nav_wrapper.dart'; // Import widget mới
import '../../services/feedback_service.dart'; // Import service mới

enum SortOption { byName, byDateAdded }

// Enum để xác định lý do phim được nổi bật (được đưa ra ngoài class)
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
  int? _selectedGenreId; // null for "All Genres"
  List<Genre> _availableGenres = [];
  SortOption _currentSortOption =
      SortOption.byDateAdded; // Giữ lại logic sắp xếp

  final GlobalKey<AnimatedListState> _downloadsListKey =
      GlobalKey<AnimatedListState>();
  List<Movie> _downloads = []; // Danh sách cục bộ để quản lý AnimatedList

  // Lưu reference để dùng trong dispose
  DownloadsProvider? _downloadsProvider;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    final movieProvider = context.read<MovieProvider>();
    _downloadsProvider = context.read<DownloadsProvider>();

    _availableGenres = movieProvider.genres;

    // Khởi tạo danh sách cục bộ và đăng ký lắng nghe thay đổi từ provider
    _downloads = List.from(_downloadsProvider!.downloadedMovies);
    _downloads = _sortMovies(
        List.from(_downloadsProvider!.downloadedMovies)); // Sort initially
    _downloadsProvider!.addListener(_onDownloadsChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _downloadsProvider
        ?.removeListener(_onDownloadsChanged); // Sử dụng reference đã lưu
    super.dispose();
  }

  // Hàm xử lý khi DownloadsProvider thay đổi
  void _onDownloadsChanged() {
    final newDownloads = context.read<DownloadsProvider>().downloadedMovies;
    if (!mounted) return; // Crucial check to prevent "deactivated widget" error

    final sortedNewDownloads =
        _sortMovies(newDownloads); // Always work with sorted lists

    // Find removed movies first to get correct indices for AnimatedList
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

    // Find added movies
    final List<Movie> addedMovies = sortedNewDownloads
        .where(
            (movie) => !_downloads.any((oldMovie) => oldMovie.id == movie.id))
        .toList();

    for (final movie in addedMovies) {
      // Determine the correct insertion index in the *current* _downloads list
      // based on the sorting criteria.
      int insertionIndex = 0;
      while (insertionIndex < _downloads.length &&
          _sortMovies([_downloads[insertionIndex], movie]).first.id !=
              movie.id) {
        insertionIndex++;
      }

      _downloads.insert(insertionIndex, movie); // Insert into local list
      _downloadsListKey.currentState?.insertItem(
        insertionIndex,
        duration: const Duration(milliseconds: 500),
      );
    }

    // After all AnimatedList operations, ensure _downloads is fully synchronized and sorted.
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
      _searchController.clear(); // This will trigger _onSearchChanged
      _selectedGenreId = null;
    });
  }

  // Hàm để xử lý sự kiện kéo để làm mới
  Future<void> _handleRefresh() async {
    // Gọi các hàm load dữ liệu từ các provider tương ứng
    await Future.wait([
      context
          .read<DownloadsProvider>()
          .loadDownloadedMovies(), // Đã sửa tên phương thức
      context.read<FavoritesProvider>().loadFavorites(),
      context.read<WatchlistProvider>().loadWatchlist(),
    ]);

    // Hiển thị SnackBar đồng nhất sau khi làm mới xong
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lists have been updated successfully!',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch MovieProvider for genres
    _availableGenres = context.watch<MovieProvider>().genres;

    // Lấy danh sách gốc từ providers và cập nhật danh sách cục bộ
    List<Movie> originalDownloads =
        context.watch<DownloadsProvider>().downloadedMovies;
    List<Movie> originalFavorites =
        context.watch<FavoritesProvider>().favorites;
    List<Movie> originalWatchlist =
        context.watch<WatchlistProvider>().watchlistMovies;

    // Sắp xếp danh sách gốc dựa trên tùy chọn đã chọn
    List<Movie> allDownloads = _sortMovies(originalDownloads);
    List<Movie> allFavorites = _sortMovies(originalFavorites);
    List<Movie> allWatchlist = _sortMovies(originalWatchlist);

    // --- Apply Search Filter ---
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

    // --- Apply Genre Filter ---
    List<Movie> filteredDownloads =
        _filterMoviesByGenre(searchFilteredDownloads);
    List<Movie> filteredFavorites =
        _filterMoviesByGenre(searchFilteredFavorites);
    List<Movie> filteredWatchlist =
        _filterMoviesByGenre(searchFilteredWatchlist);

    // Lấy phim nổi bật đầu tiên (nếu có)
    // Chỉ hiển thị phim nổi bật nếu không có tìm kiếm đang diễn ra
    // Sử dụng các danh sách gốc để xác định "recently added" nếu cần
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
      // Sắp xếp để tìm phim được thêm gần đây nhất (phải có dateAdded)
      final List<Movie> recentlyAddedSorted = List.from(allCombinedItems)
        ..sort((a, b) {
          if (a.dateAdded == null) return 1;
          if (b.dateAdded == null) return -1;
          return b.dateAdded!.compareTo(a.dateAdded!);
        });
      final Movie? mostRecent =
          recentlyAddedSorted.isNotEmpty ? recentlyAddedSorted.first : null;

      // Sắp xếp để tìm phim có rating cao nhất
      final List<Movie> highestRatedSorted = List.from(allCombinedItems)
        ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
      featuredMovie = highestRatedSorted.first;

      // Ưu tiên hiển thị "Recently Added" nếu phim có rating cao nhất cũng là phim mới nhất
      if (mostRecent != null &&
          featuredMovie != null &&
          featuredMovie.id == mostRecent.id) {
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
              // === KHU VỰC HEADER MỚI ===
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hàng chứa tiêu đề và thanh tìm kiếm/bộ lọc
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
                        const SizedBox(width: 16), // Thêm khoảng cách ở đây
                        // Thu gọn thanh tìm kiếm và bộ lọc vào đây
                        Flexible(child: _buildSearchAndFilterBar(context)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Colors.white24),
                    _buildClearFiltersButton(),
                  ],
                ),
              ),
              // Danh sách nội dung
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: Colors.pinkAccent, // Màu của vòng xoay
                  backgroundColor:
                      const Color(0xFF3A0CA3), // Màu nền của vòng xoay,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 16, bottom: 40),
                    children: [
                      if (featuredMovie !=
                          null) // Chỉ có một lời gọi _buildFeaturedMovie
                        _buildFeaturedMovie(context, featuredMovie, reason),
                      if (_searchQuery.isEmpty && _selectedGenreId == null)
                        const SizedBox(height: 20),
                      if (filteredDownloads.isNotEmpty) ...[
                        _buildDownloadsSection(
                            context), // Không truyền filteredDownloads nữa
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

  // Hàm sắp xếp một danh sách phim
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

  void _toggleWatchlist(BuildContext context, Movie movie) {
    context.read<WatchlistProvider>().toggleWatchlist(movie);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<WatchlistProvider>().isInWatchlist(movie.id)
              ? '${movie.title} added to Watchlist!'
              : '${movie.title} removed from Watchlist!',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // === FEATURED MOVIE ===
  // Helper function to navigate to movie/TV detail
  void _goToMovieDetail(BuildContext context, Movie movie) {
    context.push('/movie/${movie.id}');
  }

  // Helper function to share movie info
  void _shareMovie(BuildContext context, Movie movie) {
    FeedbackService.playSound(context);
    FeedbackService.lightImpact(context);

    // Tạm thời disable share vì package lỗi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share feature temporarily disabled')),
    );
  }

  // Helper function to play YouTube trailer
  void _playTrailer(BuildContext context, String? trailerKey) {
    if (trailerKey == null || trailerKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trailer not available for this movie'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('🎬 Playing trailer from favorites list: $trailerKey');
    print('▶️ Playing YouTube video: https://youtube.com/watch?v=$trailerKey');

    // Show YouTube player in fullscreen
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.black.withOpacity(0.85),
          body: Stack(
            children: [
              Center(
                child: YoutubePlayer(
                  controller: YoutubePlayerController(
                    initialVideoId: trailerKey,
                    flags: const YoutubePlayerFlags(
                      autoPlay: true,
                      mute: false,
                      forceHD: true,
                    ),
                  ),
                  progressIndicatorColor: Colors.pinkAccent,
                  progressColors: const ProgressBarColors(
                    playedColor: Colors.pinkAccent,
                    handleColor: Colors.pinkAccent,
                  ),
                  onReady: () {
                    print('✅ YouTube player ready');
                  },
                  bottomActions: [
                    CurrentPosition(),
                    ProgressBar(isExpanded: true),
                    RemainingDuration(),
                    const PlaybackSpeedButton(),
                  ],
                ),
              ),
              // Nút thoát ở góc trên bên phải
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to format genres
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

  // Helper function to format runtime only
  String _formatRuntimeOnly(int? runtime) {
    if (runtime == null || runtime == 0) return '';
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    if (minutes > 0) return '${minutes}m';
    return '';
  }

  // Helper widget for action buttons on the hero banner
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

  // Widget cho phim nổi bật
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
        // Không làm gì cả
        break;
    }

    return GestureDetector(
      onTap: () => _goToMovieDetail(context, movie),
      child: Container(
        height: 400, // Tăng chiều cao cho banner
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image (full width)
              CachedNetworkImage(
                imageUrl:
                    '${ApiConstants.imageBaseUrlOriginal}${movie.posterPath}',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              // 2. Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0), // Trên trong suốt
                      Colors.black.withOpacity(0.2), // Giữa hơi mờ
                      Colors.black.withOpacity(0.8), // Dưới đậm để dễ đọc text
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // 3. Content (Text and Buttons)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Movie Title
                    Text(
                      movie.title,
                      style: const TextStyle(
                        fontSize: 26, // Tiêu đề lớn hơn
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
                    // Rating, Genres, Runtime
                    Row(
                      children: [
                        _buildRatingStars(movie.voteAverage),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            // Thêm năm phát hành
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
                    // Overview Snippet
                    Text(
                      movie.overview,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    // Action Buttons
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
                            Icons.delete_outline, 'Remove', // Nút Remove mới
                            onTap: () =>
                                _removeMovieFromAllLists(context, movie)),
                      ], // Thay đổi ở đây
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

  // Hàm hiển thị hộp thoại xác nhận xóa (có thể tái sử dụng)
  Future<void> _showDeleteConfirmationDialog({
    required Movie movie,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Người dùng phải chọn một hành động
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF3A0CA3), // Màu nền cũ
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side:
              BorderSide(color: Colors.white.withOpacity(0.2)), // Thêm viền mờ
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
              Navigator.of(dialogContext).pop(); // Đóng hộp thoại
              // HapticFeedback.mediumImpact() is not conditional yet, we can add it to FeedbackService if needed
              onConfirm(); // Thực hiện hành động xóa, âm thanh sẽ được gọi trong này
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('"${movie.title}" has been removed.',
                            style: const TextStyle(color: Colors.black))),
                  ]),
                  backgroundColor: Colors.white,
                  behavior: SnackBarBehavior.floating, // Nổi lên trên
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper function to remove a movie from all lists
  void _removeMovieFromAllLists(BuildContext context, Movie movie) {
    FeedbackService.playSound(context);
    FeedbackService.lightImpact(context);
    _showDeleteConfirmationDialog(
        movie: movie,
        content:
            'Are you sure you want to remove "${movie.title}" from all your lists (Favorites, Watchlist, Downloads)?',
        onConfirm: () {
          SystemSound.play(SystemSoundType.click); // <-- Thêm âm thanh vào đây
          context.read<FavoritesProvider>().removeFavorite(movie.id);
          context.read<WatchlistProvider>().removeWatchlist(movie.id);
          context.read<DownloadsProvider>().removeDownload(movie);
        });
  }

  // === DOWNLOADS SECTION ===
  Widget _buildDownloadsSection(BuildContext context) {
    // Không nhận tham số downloads
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Remove const
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
                      'movies':
                          _downloads, // Sử dụng danh sách cục bộ _downloads
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
              // Hiệu ứng trượt từ phải sang trái
              final slideAnimation = Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation);
              return SlideTransition(position: slideAnimation, child: child);
            },
            child: _downloads.isEmpty
                ? _buildEmptyState(
                    key: const ValueKey('empty_downloads_animated'),
                    icon: Icons.cloud_off_outlined,
                    message: 'Movies you download will appear here.',
                  )
                : AnimatedList(
                    // Đóng AnimatedSwitcher ở đây
                    key: _downloadsListKey, // Gán GlobalKey
                    shrinkWrap: true, // Quan trọng khi nằm trong ListView
                    physics:
                        const NeverScrollableScrollPhysics(), // AnimatedList tự quản lý cuộn
                    initialItemCount: _downloads.length,
                    itemBuilder: (context, index, animation) {
                      // Sử dụng FadeTransition thay vì animation package
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: animation.drive(
                            Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).chain(CurveTween(curve: Curves.easeOut)),
                          ),
                          child: _buildDownloadItemWithAnimation(
                              context,
                              _downloads[index],
                              context.read<DownloadsProvider>(),
                              animation,
                              index), // Gọi đúng hàm
                        ),
                      );
                    },
                  ),
          ), // Đóng AnimatedSwitcher
        ],
      ),
    );
  }

  Widget _buildDownloadItem(
      BuildContext context, Movie movie, DownloadsProvider provider) {
    // Thêm tham số animation và index
    return _buildDownloadItemWithAnimation(
        context, movie, provider, null, null); // Hàm này chỉ là wrapper
  }

  Widget _buildDownloadItemWithAnimation(BuildContext context, Movie movie,
      DownloadsProvider provider, Animation<double>? animation, int? index) {
    // Tối ưu: Tính toán kích thước cache cho ảnh
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int memCacheWidth = (60 * devicePixelRatio).round();
    final int memCacheHeight = (90 * devicePixelRatio).round();
    final itemContent = Container(
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
              // Sử dụng kết hợp các hàm mới
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
            // Nút play thông minh: Ưu tiên trailer online, fallback sang local video
            IconButton(
              icon:
                  const Icon(Icons.play_circle_fill, color: Colors.pinkAccent),
              tooltip: 'Play Trailer (or Downloaded Video if offline)',
              onPressed: () async {
                FeedbackService.playSound(context);
                FeedbackService.lightImpact(context);

                print(
                    '🎬 Download play button pressed for: ${movie.title} (ID: ${movie.id})');
                print('🔑 TrailerKey from database: ${movie.trailerKey}');

                // Ưu tiên phát trailer YouTube nếu có trailerKey
                if (movie.trailerKey != null && movie.trailerKey!.isNotEmpty) {
                  print('✅ Playing YouTube trailer: ${movie.trailerKey}');
                  _playTrailer(context, movie.trailerKey);
                } else {
                  print('⚠️ No trailerKey found, trying local video...');
                  // Fallback: Phát video local nếu không có trailer
                  final filePath = provider.getFilePath(movie.id);
                  if (filePath != null) {
                    print('📂 Playing local file: $filePath');
                    context.push('/play-local/${movie.id}',
                        extra: {'filePath': filePath, 'title': movie.title});
                  } else {
                    print('❌ No local file found either');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('No trailer or downloaded video available'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
            // Nút xóa download (màu đỏ)
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
              begin: const Offset(-1, 0), // Hiệu ứng trượt vào từ trái
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: itemContent,
            ),
          )
        : itemContent; // Nếu không có animation (ví dụ: khi gọi từ removeItem builder), chỉ trả về nội dung
  }

  // === FAVORITES SECTION (MỚI) ===
  Widget _buildFavoritesSection(
      BuildContext context, List<Movie> favorites, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Remove const
            children: [
              Text(
                'Favorites', // Giữ nguyên tiêu đề nhỏ
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
                      'title': title, // Dùng title được truyền vào
                      'movies': favorites,
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

  // Widget cho một mục trong danh sách yêu thích (MỚI)
  Widget _buildFavoriteItem(
      BuildContext context, Movie movie, FavoritesProvider provider) {
    // Tối ưu: Tính toán kích thước cache cho ảnh
    // Tối ưu: Tính toán kích thước cache cho ảnh (Đã sửa)
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
        onTap: () => context.push('/movie/${movie.id}'),
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
              // Sử dụng kết hợp các hàm mới
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
                    SystemSoundType.click); // <-- Thêm âm thanh vào đây
                provider.toggleFavorite(movie);
              },
            );
          },
        ),
      ),
    );
  }

  // === WATCHLIST SECTION (MỚI) ===
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
                      'title': title, // Dùng title được truyền vào
                      'movies': watchlist,
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
          ), // Closes AnimatedSwitcher
        ],
      ),
    );
  }

  Widget _buildWatchlistItem(
      BuildContext context, Movie movie, WatchlistProvider provider) {
    // Tối ưu: Tính toán kích thước cache cho ảnh
    // Tối ưu: Tính toán kích thước cache cho ảnh (Đã sửa)
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
        onTap: () => context.push('/movie/${movie.id}'),
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
                // Sử dụng kết hợp các hàm mới
                '${_getGenreNames(movie)} ${_formatRuntimeOnly(movie.runtime).isNotEmpty ? '• ${_formatRuntimeOnly(movie.runtime)}' : ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            _buildRatingStars(movie.voteAverage),
          ],
        ),
        trailing: IconButton(
            icon: const Icon(Icons.bookmark_remove,
                color: Colors.pinkAccent), // Icon xóa
            onPressed: () {
              FeedbackService.playSound(context);
              FeedbackService.lightImpact(context);
              _showDeleteConfirmationDialog(
                movie: movie,
                content:
                    'Are you sure you want to remove "${movie.title}" from your watchlist?',
                onConfirm: () {
                  SystemSound.play(
                      SystemSoundType.click); // <-- Thêm âm thanh vào đây
                  provider.toggleWatchlist(movie);
                }, // toggleWatchlist sẽ xóa nếu đã có
              );
            }),
      ),
    );
  }

  // === THANH TÌM KIẾM VÀ BỘ LỌC (MỚI) ===
  Widget _buildSearchAndFilterBar(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Để Row co lại vừa đủ nội dung
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
                        // Listener sẽ tự động gọi setState
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
            top: Radius.circular(20)), // Đóng RoundedRectangleBorder
      ),
      builder: (context) {
        // Dùng StatefulBuilder để cập nhật UI bên trong bottom sheet
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
                  // Gọi lại các widget bộ lọc, nhưng truyền setModalState
                  // để chúng có thể cập nhật UI của bottom sheet.
                  _buildGenreFilter(setModalState),
                  const SizedBox(height: 16),
                  _buildSortOptions(setModalState),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      }, // Đóng builder
    );
  }

  // === NÚT XÓA BỘ LỌC ===
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

  // === BỘ LỌC THỂ LOẠI (Đã cập nhật) ===
  Widget _buildGenreFilter(StateSetter setModalState) {
    // Add "All Genres" option at the beginning
    final List<Genre> displayGenres = [
      Genre(id: 0, name: 'All Genres'), // Use 0 or a special ID for "All"
      ..._availableGenres,
    ];

    return Container(
      height: 45, // Height for the horizontal list of chips
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

  // === TÙY CHỌN SẮP XẾP (Đã cập nhật) ===
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

  // === Helper: Rating Stars ===
  Widget _buildRatingStars(double voteAverage) {
    final rating = voteAverage / 2; // Convert 10-point scale to 5-point
    final List<Widget> stars = List.generate(5, (index) {
      // Explicitly create a List<Widget>
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

  // === Helper: Empty State Widget ===
  Widget _buildEmptyState(
      {Key? key, required IconData icon, required String message}) {
    return Center(
      key: key, // Quan trọng cho AnimatedSwitcher
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
    ); // Đóng Center
  }
}
