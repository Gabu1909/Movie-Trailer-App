import 'package:flutter/material.dart';
import '../../core/data/database_helper.dart';
import '../../core/models/movie.dart';

class WatchlistProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Movie> _watchlistMovies = [];
  final Set<int> _watchlistIds = {};
  final Set<int> _processingMovies = {};
  String? _currentUserId;

  List<Movie> get watchlistMovies => _watchlistMovies;

  WatchlistProvider() {}

  void setUserId(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      if (userId != null) {
        loadWatchlist();
      } else {
        _watchlistMovies = [];
        _watchlistIds.clear();
        notifyListeners();
      }
    }
  }

  Future<void> loadWatchlist() async {
    if (_currentUserId == null) {
      _watchlistMovies = [];
      _watchlistIds.clear();
      notifyListeners();
      return;
    }

    _watchlistMovies = await _dbHelper.getWatchlist(_currentUserId!);
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
    if (_currentUserId == null) return;

    if (_processingMovies.contains(movie.id)) {
      print(
          '⏳ Movie ${movie.id} is already being processed in watchlist, skipping...');
      return;
    }

    _processingMovies.add(movie.id);

    final isCurrentlyInWatchlist = _watchlistIds.contains(movie.id);
    if (isCurrentlyInWatchlist) {
      _watchlistMovies.removeWhere((m) => m.id == movie.id);
      _watchlistIds.remove(movie.id);
    } else {
      _watchlistMovies.add(movie);
      _watchlistIds.add(movie.id);
    }
    notifyListeners();

    try {
      await _dbHelper.toggleWatchlist(movie, _currentUserId!);
    } catch (e) {
      print('❌ Error toggling watchlist: $e');
      if (isCurrentlyInWatchlist) {
        _watchlistMovies.add(movie);
        _watchlistIds.add(movie.id);
      } else {
        _watchlistMovies.removeWhere((m) => m.id == movie.id);
        _watchlistIds.remove(movie.id);
      }
      notifyListeners();
    } finally {
      _processingMovies.remove(movie.id);
    }
  }

  Future<void> removeWatchlist(int movieId) async {
    if (_currentUserId == null) return;
    await _dbHelper.removeWatchlist(movieId, _currentUserId!);
    _watchlistMovies.removeWhere((m) => m.id == movieId);
    _watchlistIds.remove(movieId);
    notifyListeners();
  }

  void clearWatchlist() {
    _watchlistMovies = [];
    _watchlistIds.clear();
    _currentUserId = null;
    notifyListeners();
  }
}
