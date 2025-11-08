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
    _favorites = await _dbHelper.getFavorites();
    notifyListeners();
  }

  bool isFavorite(int movieId) {
    return _favorites.any((movie) => movie.id == movieId);
  }

  Future<void> toggleFavorite(Movie movie) async {
    if (isFavorite(movie.id)) {
      await _dbHelper.removeFavorite(movie.id);
    } else {
      await _dbHelper.addFavorite(movie);
    }
    await loadFavorites();
  }

  Future<void> removeFavorite(int movieId) async {
    await _dbHelper.removeFavorite(movieId);
    await loadFavorites();
  }
}
