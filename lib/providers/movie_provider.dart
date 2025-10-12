import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/movie.dart';

class MovieProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Danh sách dữ liệu chính
  List<Movie> _nowPlayingMovies = [];
  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _searchedMovies = [];

  bool _isLoading = false; // Trạng thái loading chung cho các request

  // Getters công khai
  List<Movie> get nowPlayingMovies => _nowPlayingMovies;
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get searchedMovies => _searchedMovies;
  bool get isLoading => _isLoading;

  // Tải tất cả các danh sách phim chính (Now Playing, Popular, Top Rated)
  Future<void> fetchAllMovies() async {
    _isLoading = true;
    notifyListeners(); // Bắt đầu loading

    try {
      // Thực hiện các API call đồng thời (tối ưu hiệu suất)
      final results = await Future.wait([
        _apiService.getNowPlayingMovies(),
        _apiService.getPopularMovies(),
        _apiService.getTopRatedMovies(),
      ]);

      _nowPlayingMovies = results[0];
      _popularMovies = results[1];
      _topRatedMovies = results[2];
    } catch (e) {
      // Xử lý lỗi nếu cần
      print('Error fetching movies: $e');
    }

    _isLoading = false;
    notifyListeners(); // Kết thúc loading và cập nhật UI
  }

  // Tìm kiếm phim
  Future<void> searchMovies(String query) async {
    _isLoading = true;
    _searchedMovies = []; // Xóa kết quả cũ trước khi tìm kiếm mới
    notifyListeners();

    try {
      if (query.isNotEmpty) {
        _searchedMovies = await _apiService.searchMovies(query);
      }
    } catch (e) {
      print('Error searching movies: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
