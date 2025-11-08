import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/movie.dart';

class WatchlistProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Movie> _watchlistMovies = [];
  final Set<int> _watchlistIds = {};

  List<Movie> get watchlistMovies => _watchlistMovies;

  WatchlistProvider() {
    loadWatchlist();
  }

  Future<void> loadWatchlist() async {
    _watchlistMovies = await _dbHelper.getWatchlist();
    _watchlistIds.clear();
    for (var movie in _watchlistMovies) {
      _watchlistIds.add(movie.id);
    }
    notifyListeners();
  }

  bool isInWatchlist(int movieId) {
    return _watchlistIds.contains(movieId);
  }

  Future<void> toggleWatchlist(Movie movie) async {
    // The DB helper now handles the logic of toggling the flag.
    await _dbHelper.toggleWatchlist(movie);
    // Reload from the database to ensure consistency.
    await loadWatchlist();
  }
}
