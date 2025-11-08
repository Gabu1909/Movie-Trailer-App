import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../providers/downloads_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/movie_card.dart';

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
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              tooltip: 'Delete Download',
              onPressed: () async {
                await provider.removeDownload(movie);
                // Refresh the list after deletion
                setState(() {
                  _sortedMovies.removeWhere((m) => m.id == movie.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${movie.title} removed from downloads.')),
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
          onPressed: () async {
            await provider.toggleFavorite(movie);
            // Refresh the list after removal
            setState(() {
              _sortedMovies.removeWhere((m) => m.id == movie.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${movie.title} removed from favorites.')),
            );
          },
        );
      case MyListType.watchlist:
        final provider = context.read<WatchlistProvider>();
        return IconButton(
          icon: const Icon(Icons.bookmark_remove, color: Colors.pinkAccent),
          tooltip: 'Remove from Watchlist',
          onPressed: () async {
            await provider.toggleWatchlist(movie);
            // Refresh the list after removal
            setState(() {
              _sortedMovies.removeWhere((m) => m.id == movie.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('${movie.title} removed from your watchlist.')),
            );
          },
        );
    }
  }
}
