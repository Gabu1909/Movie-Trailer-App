import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/models/cast.dart';
import '../../core/models/movie.dart';

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

  void clearResults() {
    _query = '';
    _movies = [];
    _actors = [];
    notifyListeners();
  }

  void setSearchType(SearchType type) {
    if (_searchType != type) {
      _searchType = type;
      if (_query.isNotEmpty) {
        search(_query);
      } else {
        notifyListeners();
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
        _actors = [];
      } else {
        _actors = await _apiService.searchActors(_query);
        _movies = [];
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
