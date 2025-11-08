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
    await _dbHelper.toggleWatchlist(movie);
    final isNowInWatchlist = !isInWatchlist(movie.id);
    if (isNowInWatchlist) {
      _watchlistMovies.add(movie);
      _watchlistIds.add(movie.id);
    } else {
      _watchlistMovies.removeWhere((m) => m.id == movie.id);
      _watchlistIds.remove(movie.id);
    }
    notifyListeners();
  }

  Future<void> removeWatchlist(int movieId) async {
    await _dbHelper
        .removeWatchlist(movieId); // Assuming _dbHelper has removeWatchlist
    _watchlistMovies.removeWhere((m) => m.id == movieId);
    _watchlistIds.remove(movieId);
    notifyListeners();
  }
}
