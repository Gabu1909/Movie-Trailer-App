import 'package:flutter/material.dart';
import 'dart:async'; // Import for Completer
import '../api/api_service.dart';
import '../models/genre.dart';
import '../models/movie.dart';

class MovieProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Movie> _popularMovies = []; // Cho "Trending"
  List<Movie> _trendingMovies =
      []; // Danh sách phim cho carousel, có thể thay đổi
  List<Movie> _upcomingMovies = []; // Cho "Coming Soon"
  List<Movie> _kidsMovies = []; // Cho "Best for Kids"
  List<Movie> _topRatedMovies = []; // Dự phòng
  List<Movie> _searchedMovies = [];
  List<Genre> _genres = [];

  // Bộ đệm để lưu trữ phim theo genreId
  final Map<int, List<Movie>> _cachedGenreMovies = {};

  bool _isLoading = true;
  bool _isTrendingLoading = false;
  int _selectedGenreIndex = 0; // Lưu trạng thái tab đã chọn

  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get upcomingMovies => _upcomingMovies;
  List<Movie> get kidsMovies => _kidsMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get searchedMovies => _searchedMovies;
  List<Genre> get genres => _genres;
  bool get isLoading => _isLoading;
  bool get isTrendingLoading => _isTrendingLoading;
  int get selectedGenreIndex => _selectedGenreIndex;

  // Completer để báo hiệu khi quá trình khởi tạo hoàn tất
  final Completer<void> _initializationCompleter = Completer<void>();
  Future<void> get initializationComplete => _initializationCompleter.future;

  MovieProvider() {
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    _isLoading = true;
    notifyListeners();

    // Xóa bộ đệm phim theo thể loại khi làm mới toàn bộ dữ liệu
    _cachedGenreMovies.clear();

    try {
      await Future.wait([
        _apiService.getPopularMovies(),
        _apiService.getUpcomingMovies(),
        _apiService.getMoviesByGenre(10751), // 10751 = Family
        _apiService.getGenres(),
        _apiService.getTopRatedMovies(),
      ]).then((results) {
        _popularMovies = results[0] as List<Movie>;
        _trendingMovies = _popularMovies; // Ban đầu, trending = popular
        _upcomingMovies = results[1] as List<Movie>;
        _kidsMovies = results[2] as List<Movie>;
        _genres = results[3] as List<Genre>;
        _topRatedMovies = results[4] as List<Movie>;
        // Lưu danh sách phim "Popular" vào bộ đệm với key là 0
        _cachedGenreMovies[0] = _popularMovies;
      });
    } catch (e) {
      // Xử lý lỗi (ví dụ: in ra console)
      debugPrint('Error fetching data: $e');
    } finally {
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete(); // Báo hiệu hoàn tất
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchMovies(String query) async {
    _isLoading = true;
    _searchedMovies = [];
    notifyListeners();
    if (query.isNotEmpty) {
      try {
        _searchedMovies = await _apiService.searchMovies(query);
      } catch (e) {
        debugPrint('Error searching movies: $e');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  // Hàm mới để cập nhật phim cho carousel "Trending"
  Future<void> fetchTrendingMoviesByGenre(int? genreId) async {
    _isTrendingLoading = true;
    notifyListeners();

    try {
      final id = genreId ?? 0; // Sử dụng 0 nếu genreId là null

      // 1. Kiểm tra trong bộ đệm trước
      if (_cachedGenreMovies.containsKey(id)) {
        _trendingMovies = _cachedGenreMovies[id]!;
      } else {
        // 2. Nếu không có, gọi API
        final movies = await _apiService.getMoviesByGenre(id);
        _trendingMovies = movies;
        // 3. Lưu kết quả vào bộ đệm
        _cachedGenreMovies[id] = movies;
      }
    } catch (e) {
      debugPrint('Error fetching trending movies by genre: $e');
    }
    _isTrendingLoading = false;
    notifyListeners();
  }

  // Hàm mới để chọn thể loại và fetch dữ liệu
  Future<void> selectGenre(int index, int? genreId) async {
    _selectedGenreIndex = index;
    // Không cần notifyListeners() ở đây vì fetchTrendingMoviesByGenre sẽ làm điều đó
    await fetchTrendingMoviesByGenre(genreId);
  }
}
