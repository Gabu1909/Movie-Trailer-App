import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../providers/downloads_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/watchlist_provider.dart';
import 'package:flutter/services.dart'; // For SystemSound
import '../widgets/movie_card.dart';
import 'feedback_service.dart'; // Import service mới

enum MyListType { downloads, favorites, watchlist }

enum SortOption { byName, byDateAdded }

class MyListSeeAllScreen extends StatefulWidget {
  final String title;
  final List<Movie> movies;
  final MyListType listType;

  const MyListSeeAllScreen({
    super.key,
    required this.title,
    required this.movies,
    required this.listType,
  });

  @override
  State<MyListSeeAllScreen> createState() => _MyListSeeAllScreenState();
}

class _MyListSeeAllScreenState extends State<MyListSeeAllScreen> {
  late List<Movie> _sortedMovies;
  SortOption _currentSortOption = SortOption.byDateAdded;

  @override
  void initState() {
    super.initState();
    _sortedMovies = List.from(widget.movies);
    _sortMovies();
  }

  void _sortMovies() {
    setState(() {
      switch (_currentSortOption) {
        case SortOption.byName:
          _sortedMovies.sort((a, b) => a.title.compareTo(b.title));
          break;
        case SortOption.byDateAdded:
          // Since we don't have a date, we reverse the list to show newest first.
          // This assumes the original list from the provider is in insertion order.
          _sortedMovies = List<Movie>.from(widget.movies.reversed);
          break;
      }
    });
  }

  // Hàm hiển thị hộp thoại xác nhận xóa (tái sử dụng từ FavoritesScreen)
  Future<void> _showDeleteConfirmationDialog({
    required Movie movie,
    required String content,
    required VoidCallback onConfirm,
    required String successMessage,
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
              HapticFeedback.mediumImpact();
              onConfirm(); // Thực hiện hành động xóa, âm thanh sẽ được gọi trong onConfirm
              SystemSound.play(SystemSoundType.click); // Phát âm thanh "ting"
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(successMessage,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<SortOption>(
            onSelected: (SortOption result) {
              setState(() {
                _currentSortOption = result;
                _sortMovies();
              });
            },
            icon: const Icon(Icons.sort),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.byDateAdded,
                child: Text('Sort by Date Added'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.byName,
                child: Text('Sort by Name (A-Z)'),
              ),
            ],
          ),
        ],
      ),
      body: _sortedMovies.isEmpty
          ? Center(
              child: Text(
                'No movies to display.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2 / 3.5, // Adjusted for actions
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _sortedMovies.length,
              itemBuilder: (context, index) {
                final movie = _sortedMovies[index];
                return _buildMovieItem(context, movie);
              },
            ),
    );
  }

  Widget _buildMovieItem(BuildContext context, Movie movie) {
    return Column(
      children: [
        Expanded(
          child: MovieCard(movie: movie),
        ),
        const SizedBox(height: 8),
        _buildActionButtons(context, movie),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Movie movie) {
    switch (widget.listType) {
      case MyListType.downloads:
        final provider = context.read<DownloadsProvider>();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.play_circle_fill, color: Colors.pinkAccent),
              tooltip: 'Play',
              onPressed: () {
                final filePath = provider.getFilePath(movie.id);
                if (filePath != null) {
                  context.push('/play-local/${movie.id}',
                      extra: {'filePath': filePath, 'title': movie.title});
                }
                FeedbackService.playSound(context);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              tooltip: 'Delete Download',
              onPressed: () {
                _showDeleteConfirmationDialog(
                  // No haptic here, it's handled by the dialog's confirm button
                  movie: movie,
                  content:
                      'Are you sure you want to remove "${movie.title}" from your downloads?',
                  onConfirm: () async {
                    SystemSound.play(SystemSoundType.click);
                    await provider.removeDownload(movie);
                    setState(() {
                      _sortedMovies.removeWhere((m) => m.id == movie.id);
                    });
                  },
                  successMessage: '${movie.title} removed from downloads.',
                );
              },
            ),
          ],
        );
      case MyListType.favorites:
        final provider = context.read<FavoritesProvider>(); // Get provider here
        return IconButton(
          icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
          tooltip: 'Remove from Favorites',
          onPressed: () {
            // No haptic here, it's handled by the dialog's confirm button
            _showDeleteConfirmationDialog(
              movie: movie,
              content:
                  'Are you sure you want to remove "${movie.title}" from your favorites?',
              onConfirm: () async {
                SystemSound.play(SystemSoundType.click);
                await provider.toggleFavorite(movie);
                setState(() {
                  _sortedMovies.removeWhere((m) => m.id == movie.id);
                });
              },
              successMessage: '${movie.title} removed from favorites.',
            );
          },
        );
      case MyListType.watchlist:
        final provider = context.read<WatchlistProvider>(); // Get provider here
        return IconButton(
          icon: const Icon(Icons.bookmark_remove, color: Colors.pinkAccent),
          tooltip: 'Remove from Watchlist',
          onPressed: () {
            // No haptic here, it's handled by the dialog's confirm button
            _showDeleteConfirmationDialog(
              movie: movie,
              content:
                  'Are you sure you want to remove "${movie.title}" from your watchlist?',
              onConfirm: () async {
                SystemSound.play(SystemSoundType.click);
                await provider.toggleWatchlist(movie);
                setState(() {
                  _sortedMovies.removeWhere((m) => m.id == movie.id);
                });
              },
              successMessage: '${movie.title} removed from your watchlist.',
            );
          },
        );
    }
  }
}
