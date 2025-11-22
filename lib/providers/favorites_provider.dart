import 'package:flutter/material.dart';
import '../../core/data/database_helper.dart';
import '../../core/models/movie.dart';

class FavoritesProvider with ChangeNotifier {
  List<Movie> _favorites = [];
  List<Movie> get favorites => _favorites;
  String? _currentUserId;
  final Set<int> _processingMovies = {}; 

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  FavoritesProvider() {
  }

  void setUserId(String? userId) {
    print('FavoritesProvider: setUserId called with userId: $userId');
    if (_currentUserId != userId) {
      _currentUserId = userId;
      if (userId != null) {
        print('Loading favorites for user $userId...');
        loadFavorites();
      } else {
        print('Clearing favorites (no user)');
        _favorites = [];
        notifyListeners();
      }
    }
  }

  Future<void> loadFavorites() async {
    if (_currentUserId == null) {
      _favorites = [];
      notifyListeners();
      return;
    }

    final allFavorites = await _dbHelper.getFavorites(_currentUserId!);
    _favorites = allFavorites.where((m) {
      try {
        m.id;
        return true;
      } catch (e) {
        print('Skipping a favorite with an invalid ID: $e');
        return false;
      }
    }).toList();
    notifyListeners();
  }

  bool isFavorite(int movieId) {
    return _favorites.any((movie) => movie.id == movieId);
  }

  Future<void> toggleFavorite(Movie movie) async {
    if (_currentUserId == null) {
      print('FavoritesProvider: Cannot toggle favorite - userId is null');
      return;
    }

    if (_processingMovies.contains(movie.id)) {
      print(
          'FavoritesProvider: Movie ${movie.id} is already being processed, skipping...');
      return;
    }

    _processingMovies.add(movie.id);
    print(
        'FavoritesProvider: Toggling favorite for movie ${movie.id} with userId $_currentUserId');
    final isCurrentlyFavorite = isFavorite(movie.id);

    if (isCurrentlyFavorite) {
      _favorites.removeWhere((m) => m.id == movie.id);
    } else {
      _favorites.add(movie);
    }
    notifyListeners(); 

    try {
      if (isCurrentlyFavorite) {
        print('Removing from favorites...');
        await _dbHelper.removeFavorite(movie.id, _currentUserId!);
      } else {
        print('Adding to favorites...');
        await _dbHelper.addFavorite(movie, _currentUserId!);
      }
      print('Favorites updated successfully');
    } catch (e) {
      print('Error toggling favorite: $e');
      if (isCurrentlyFavorite) {
        _favorites.add(movie);
      } else {
        _favorites.removeWhere((m) => m.id == movie.id);
      }
      notifyListeners();
    } finally {
      _processingMovies.remove(movie.id);
    }
  }

  Future<void> removeFavorite(int movieId) async {
    if (_currentUserId == null) return;
    await _dbHelper.removeFavorite(movieId, _currentUserId!);
    await loadFavorites();
  }

  void clearFavorites() {
    _favorites = [];
    _currentUserId = null;
    notifyListeners();
  }
}
