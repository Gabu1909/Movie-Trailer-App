import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/movie.dart';

class FavoritesProvider with ChangeNotifier {
  List<Movie> _favorites = [];
  List<Movie> get favorites => _favorites;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  FavoritesProvider() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final allFavorites = await _dbHelper.getFavorites();
    // Defensive coding: Filter out any movies that might have a bad ID
    _favorites = allFavorites.where((m) {
      try {
        // This access will throw if the 'id' is not initialized (LateInitializationError)
        m.id;
        return true;
      } catch (e) {
        // Log the error and exclude the invalid movie from the list
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
    final isCurrentlyFavorite = isFavorite(movie.id);
    if (isCurrentlyFavorite) {
      await _dbHelper.removeFavorite(movie.id);
    } else {
      await _dbHelper.addFavorite(movie);
    }
    // Reload from the database to ensure consistency.
    await loadFavorites();
  }

  Future<void> removeFavorite(int movieId) async {
    await _dbHelper.removeFavorite(movieId);
    await loadFavorites();
  }
}
