import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/movie.dart';
import '../../providers/downloads_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../providers/watchlist_provider.dart';
import 'package:flutter/services.dart'; 
import '../../../shared/widgets/cards/movie_card.dart';
import '../../../core/services/feedback_service.dart'; 

enum MyListType { downloads, favorites, watchlist }

enum SortOption { byName, byDateAdded }

class MyListSeeAllScreen extends StatefulWidget {
  final String title;
  final MyListType listType;

  const MyListSeeAllScreen({
    super.key,
    required this.title,
    required this.listType,
  });

  @override
  State<MyListSeeAllScreen> createState() => _MyListSeeAllScreenState();
}

class _MyListSeeAllScreenState extends State<MyListSeeAllScreen> {
  SortOption _currentSortOption = SortOption.byDateAdded;

  List<Movie> _getSortedMovies(List<Movie> movies) {
    final sortedList = List<Movie>.from(movies);
    switch (_currentSortOption) {
      case SortOption.byName:
        sortedList.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.byDateAdded:
        return sortedList.reversed.toList();
    }
    return sortedList;
  }

  List<Movie> _getCurrentMovies(BuildContext context) {
    switch (widget.listType) {
      case MyListType.downloads:
        return context.watch<DownloadsProvider>().downloadedMovies;
      case MyListType.favorites:
        return context.watch<FavoritesProvider>().favorites;
      case MyListType.watchlist:
        return context.watch<WatchlistProvider>().watchlistMovies;
    }
  }

  Future<void> _showDeleteConfirmationDialog({
    required Movie movie,
    required String content,
    required VoidCallback onConfirm,
    required String successMessage,
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
              HapticFeedback.mediumImpact();
              onConfirm(); 
              SystemSound.play(SystemSoundType.click); 
              UIHelpers.showSuccessSnackBar(context, successMessage);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMovies = _getCurrentMovies(context);
    final sortedMovies = _getSortedMovies(currentMovies);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<SortOption>(
            onSelected: (SortOption result) {
              setState(() {
                _currentSortOption = result;
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
      body: sortedMovies.isEmpty
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
                childAspectRatio: 2 / 3.5, 
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: sortedMovies.length,
              itemBuilder: (context, index) {
                final movie = sortedMovies[index];
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
                  movie: movie,
                  content:
                      'Are you sure you want to remove "${movie.title}" from your downloads?',
                  onConfirm: () async {
                    SystemSound.play(SystemSoundType.click);
                    await provider.removeDownload(movie);
                  },
                  successMessage: '${movie.title} removed from downloads.',
                );
              },
            ),
          ],
        );
      case MyListType.favorites:
        final provider = context.read<FavoritesProvider>(); 
        return IconButton(
          icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
          tooltip: 'Remove from Favorites',
          onPressed: () {
            _showDeleteConfirmationDialog(
              movie: movie,
              content:
                  'Are you sure you want to remove "${movie.title}" from your favorites?',
              onConfirm: () async {
                SystemSound.play(SystemSoundType.click);
                await provider.toggleFavorite(movie);
              },
              successMessage: '${movie.title} removed from favorites.',
            );
          },
        );
      case MyListType.watchlist:
        final provider = context.read<WatchlistProvider>(); 
        return IconButton(
          icon: const Icon(Icons.bookmark_remove, color: Colors.pinkAccent),
          tooltip: 'Remove from Watchlist',
          onPressed: () {
            _showDeleteConfirmationDialog(
              movie: movie,
              content:
                  'Are you sure you want to remove "${movie.title}" from your watchlist?',
              onConfirm: () async {
                SystemSound.play(SystemSoundType.click);
                await provider.toggleWatchlist(movie);
              },
              successMessage: '${movie.title} removed from your watchlist.',
            );
          },
        );
    }
  }
}
