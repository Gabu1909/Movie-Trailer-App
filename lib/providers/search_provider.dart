import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/cast.dart';
import '../models/movie.dart';

enum SearchType { movie, person }

class SearchProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _query = '';
  SearchType _searchType = SearchType.movie;
  bool _isLoading = false;

  List<Movie> _movies = [];
  List<Cast> _actors = [];

  String get query => _query;
  SearchType get searchType => _searchType;
  bool get isLoading => _isLoading;
  List<Movie> get movies => _movies;
  List<Cast> get actors => _actors;

  void setSearchType(SearchType type) {
    if (_searchType != type) {
      _searchType = type;
      // Chạy lại tìm kiếm với query hiện tại cho loại mới
      if (_query.isNotEmpty) {
        search(_query);
      } else {
        notifyListeners(); // Cập nhật UI để hiển thị đúng tab
      }
    }
  }

  Future<void> search(String newQuery) async {
    _query = newQuery.trim();

    if (_query.isEmpty) {
      _movies = [];
      _actors = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (_searchType == SearchType.movie) {
        _movies = await _apiService.searchMovies(_query);
        _actors = []; // Xóa kết quả của loại kia
      } else {
        _actors = await _apiService.searchActors(_query);
        _movies = []; // Xóa kết quả của loại kia
      }
    } catch (e) {
      debugPrint('Search failed: $e');
      _movies = [];
      _actors = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
