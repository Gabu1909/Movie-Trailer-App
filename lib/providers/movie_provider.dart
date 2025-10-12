import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/genre.dart';
import '../models/movie.dart';

class MovieProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Movie> _nowPlayingMovies = [];
  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _searchedMovies = [];
  List<Genre> _genres = []; // MỚI: Danh sách thể loại

  bool _isLoading = true;

  List<Movie> get nowPlayingMovies => _nowPlayingMovies;
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get searchedMovies => _searchedMovies;
  List<Genre> get genres => _genres; // MỚI
  bool get isLoading => _isLoading;

  MovieProvider() {
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    _isLoading = true;
    notifyListeners();

    // Tải đồng thời tất cả dữ liệu
    await Future.wait([
      _apiService.getNowPlayingMovies(),
      _apiService.getPopularMovies(),
      _apiService.getTopRatedMovies(),
      _apiService.getGenres(),
    ]).then((results) {
      _nowPlayingMovies = results[0] as List<Movie>;
      _popularMovies = results[1] as List<Movie>;
      _topRatedMovies = results[2] as List<Movie>;
      _genres = results[3] as List<Genre>;
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchMovies(String query) async {
    _isLoading = true;
    _searchedMovies = [];
    notifyListeners();
    if (query.isNotEmpty) {
      _searchedMovies = await _apiService.searchMovies(query);
    }
    _isLoading = false;
    notifyListeners();
  }
}
