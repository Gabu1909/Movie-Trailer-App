import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/movie.dart';

class FavoritesProvider with ChangeNotifier {
  List<Movie> _favorites = [];
  List<Movie> get favorites => _favorites;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Constructor: Tải danh sách yêu thích ngay khi Provider được tạo
  FavoritesProvider() {
    loadFavorites();
  }

  // Tải danh sách từ database
  Future<void> loadFavorites() async {
    _favorites = await _dbHelper.getFavorites();
    notifyListeners();
  }

  // Kiểm tra một phim có phải là yêu thích hay không
  bool isFavorite(int movieId) {
    return _favorites.any((movie) => movie.id == movieId);
  }

  // Thêm/Xóa phim khỏi danh sách yêu thích
  Future<void> toggleFavorite(Movie movie) async {
    if (isFavorite(movie.id)) {
      // Đã có -> Xóa
      await _dbHelper.removeFavorite(movie.id);
    } else {
      // Chưa có -> Thêm
      await _dbHelper.addFavorite(movie);
    }
    // Sau khi thay đổi, tải lại danh sách để cập nhật UI
    await loadFavorites();
  }
}
