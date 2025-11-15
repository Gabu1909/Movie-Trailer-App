import 'package:flutter/material.dart';
import 'dart:async'; // Import for Completer
import '../api/api_service.dart';
import '../models/actor_detail.dart';
import '../models/genre.dart';
import '../models/movie.dart';
import '../utils/filter_helper.dart';
import 'notification_provider.dart';

class MovieProvider with ChangeNotifier, WidgetsBindingObserver {
  final ApiService _apiService;
  final NotificationProvider? _notificationProvider;

  List<Movie> _popularMovies = []; // Cho "Trending"
  List<Movie> _trendingMovies =
      []; // Danh sách phim cho carousel, có thể thay đổi
  List<Movie> _upcomingMovies = []; // Cho "Coming Soon"
  List<Movie> _kidsMovies = []; // Cho "Best for Kids"
  List<Movie> _topRatedMovies = []; // Dự phòng
  List<Movie> _nowPlayingMovies = []; // Phim mới phát hành
  List<Movie> _weeklyTrendingMovies = []; // Phim hot nhất tuần
  List<Movie> _searchedMovies = [];
  bool _isDisposed = false; // Cờ để kiểm tra trạng thái disposed
  List<Genre> _genres = [];

  // Bộ đệm để lưu trữ phim theo genreId
  final Map<int, List<Movie>> _cachedGenreMovies = {};

  bool _isLoading = true;
  bool _isTrendingLoading = false;
  bool _isFilterLoading = false;
  // Thêm các biến cho việc tải thêm phim "sắp ra mắt"
  Timer? _trendingRefreshTimer;
  bool _isFetchingMoreUpcoming = false;
  int _upcomingPage = 1;
  bool _hasMoreUpcoming = true;

  int _selectedGenreIndex = 0; // Lưu trạng thái tab đã chọn

  // Drawer filters state
  List<int> _selectedDrawerGenreIds = [];
  List<String> _selectedCountries = [];

  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get upcomingMovies => _upcomingMovies;
  List<Movie> get kidsMovies => _kidsMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get nowPlayingMovies => _nowPlayingMovies;
  List<Movie> get weeklyTrendingMovies => _weeklyTrendingMovies;
  List<Movie> get searchedMovies => _searchedMovies;
  List<Genre> get genres => _genres;
  bool get isLoading => _isLoading;
  bool get isTrendingLoading => _isTrendingLoading;
  bool get isFilterLoading => _isFilterLoading;
  bool get isFetchingMoreUpcoming => _isFetchingMoreUpcoming;

  int get selectedGenreIndex => _selectedGenreIndex;
  List<int> get selectedDrawerGenreIds => _selectedDrawerGenreIds;
  List<String> get selectedCountries => _selectedCountries;

  // Completer để báo hiệu khi quá trình khởi tạo hoàn tất
  final Completer<void> _initializationCompleter = Completer<void>();
  Future<void> get initializationComplete => _initializationCompleter.future;

  MovieProvider(this._apiService, [this._notificationProvider]) {
    WidgetsBinding.instance.addObserver(this);
    fetchAllData();
    _startTrendingTimer(); // Bắt đầu bộ đếm thời gian tự động làm mới
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App vào background, pause timer để tiết kiệm pin
      _trendingRefreshTimer?.cancel();
      debugPrint('⏸️ Timer paused - app in background');
    } else if (state == AppLifecycleState.resumed) {
      // App quay lại foreground, resume timer
      _startTrendingTimer();
      debugPrint('▶️ Timer resumed - app in foreground');
    }
  }

  Future<void> fetchAllData() async {
    _isLoading = true;
    _safeNotifyListeners();
    // Thêm dòng này để kích hoạt shimmer cho Trending section khi refresh
    _isTrendingLoading = true;
    _safeNotifyListeners();

    // Xóa bộ đệm phim theo thể loại khi làm mới toàn bộ dữ liệu
    _cachedGenreMovies.clear();

    try {
      final results = await Future.wait([
        _apiService.getPopularMovies(),
        _apiService.getUpcomingMovies(),
        _apiService.getMoviesByGenre('10751'), // 10751 = Family
        _apiService.getGenres(),
        _apiService.getTopRatedMovies(),
        _apiService.getNowPlayingMovies(),
        _apiService.getTrendingMoviesOfWeek(), // Thêm lại API call
      ]);
      _popularMovies = results[0] as List<Movie>;
      _trendingMovies = _popularMovies; // Ban đầu, trending = popular

      // Sắp xếp phim sắp ra mắt theo ngày phát hành giảm dần (mới nhất lên đầu)
      final upcoming = results[1] as List<Movie>;
      upcoming.sort((a, b) {
        if (a.releaseDate == null)
          return 1; // Phim không có ngày ra mắt xuống cuối
        if (b.releaseDate == null) return -1;
        return b.releaseDate!.compareTo(a.releaseDate!); // So sánh ngược
      });
      _upcomingMovies = upcoming;
      _kidsMovies = results[2] as List<Movie>;
      _genres = results[3] as List<Genre>;
      _topRatedMovies = results[4] as List<Movie>;
      _nowPlayingMovies = results[5] as List<Movie>;
      _weeklyTrendingMovies = results[6] as List<Movie>; // Kích hoạt lại

      _cachedGenreMovies[0] = _popularMovies;

      _createActorNotifications();
    } catch (e) {
      // Xử lý lỗi (ví dụ: in ra console)
      debugPrint('Error fetching data: $e');
    } finally {
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete(); // Báo hiệu hoàn tất
      }
    }

    _isLoading = false;
    _isTrendingLoading = false; // Tắt shimmer cho Trending khi có dữ liệu
    _safeNotifyListeners();
  }

  // Hàm mới để xử lý việc tạo thông báo cho diễn viên
  Future<void> _createActorNotifications() async {
    if (_notificationProvider == null) return;

    try {
      final popularActors = await _apiService.getPopularActors();
      // Chỉ xử lý cho 3 diễn viên hot nhất để tránh quá nhiều API call
      for (final actor in popularActors.take(3)) {
        final ActorDetail actorDetail =
            await _apiService.getActorDetails(actor.id);

        // Lấy danh sách phim của diễn viên và sắp xếp theo ngày phát hành
        final List<Movie> movieCredits = actorDetail.movieCredits;
        if (movieCredits.isEmpty) continue;

        movieCredits.sort((a, b) {
          final dateA = a.releaseDate;
          final dateB = b.releaseDate;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA); // Sắp xếp mới nhất lên đầu
        });

        // Lấy phim mới nhất và tạo thông báo
        final latestMovie = movieCredits.first;
        _notificationProvider.addActorInNewMovieNotification(
            actor, latestMovie);
      }
    } catch (e) {
      debugPrint('Error creating actor notifications: $e');
    }
  }

  Future<void> searchMovies(String query) async {
    _isLoading = true;
    _searchedMovies = [];
    _safeNotifyListeners();
    if (query.isNotEmpty) {
      try {
        _searchedMovies = await _apiService.searchMovies(query);
      } catch (e) {
        debugPrint('Error searching movies: $e');
      }
    }
    _isLoading = false;
    _safeNotifyListeners();
  }

  // Hàm mới để cập nhật phim cho carousel "Trending"
  Future<void> fetchTrendingMoviesByGenre(int? genreId) async {
    _isTrendingLoading = true;
    _safeNotifyListeners();

    try {
      final id = genreId ?? 0; // Sử dụng 0 nếu genreId là null

      // 1. Kiểm tra trong bộ đệm trước
      if (_cachedGenreMovies.containsKey(id)) {
        _trendingMovies = _cachedGenreMovies[id]!;
      } else {
        // 2. Nếu không có, gọi API
        final movies = await _apiService.getMoviesByGenre(id.toString());
        _trendingMovies = movies;
        // 3. Lưu kết quả vào bộ đệm
        _cachedGenreMovies[id] = movies;
      }
    } catch (e) {
      debugPrint('Error fetching trending movies by genre: $e');
    }
    _isTrendingLoading = false;
    _safeNotifyListeners();
  }

  // Hàm mới để chọn thể loại và fetch dữ liệu
  Future<void> selectGenre(int index, int? genreId) async {
    _selectedGenreIndex = index;
    // Không cần notifyListeners() ở đây vì fetchTrendingMoviesByGenre sẽ làm điều đó
    await fetchTrendingMoviesByGenre(genreId);
  }

  // Hàm mới để bắt đầu bộ đếm thời gian tự động làm mới
  void _startTrendingTimer() {
    // Hủy bỏ bất kỳ bộ đếm thời gian cũ nào nếu có
    _trendingRefreshTimer?.cancel();

    // Thiết lập bộ đếm thời gian mới, chạy mỗi 15 phút
    _trendingRefreshTimer =
        Timer.periodic(const Duration(minutes: 15), (timer) {
      debugPrint('⏰ Tự động làm mới danh sách phim thịnh hành...');

      // Lấy genreId của tab đang được chọn
      int? genreId;
      if (_selectedGenreIndex > 0 && _genres.isNotEmpty) {
        genreId = _genres[_selectedGenreIndex - 1].id;
      }
      // Gọi hàm fetch lại dữ liệu cho tab đó
      fetchTrendingMoviesByGenre(genreId);
    });
  }

  // Hàm mới để tải thêm phim "sắp ra mắt"
  Future<void> fetchMoreUpcomingMovies() async {
    if (_isFetchingMoreUpcoming || !_hasMoreUpcoming) return;

    _isFetchingMoreUpcoming = true;
    _safeNotifyListeners();

    try {
      _upcomingPage++;
      final moreMovies =
          await _apiService.getUpcomingMovies(page: _upcomingPage);
      if (moreMovies.isNotEmpty) {
        // Sắp xếp danh sách phim mới tải về trước khi thêm vào
        moreMovies.sort((a, b) {
          if (a.releaseDate == null) return 1;
          if (b.releaseDate == null) return -1;
          return b.releaseDate!.compareTo(a.releaseDate!);
        });
        // Thêm danh sách đã sắp xếp vào cuối danh sách hiện tại
        _upcomingMovies.addAll(moreMovies);
      } else {
        _hasMoreUpcoming = false; // Không còn phim để tải
      }
    } catch (e) {
      debugPrint('Error fetching more upcoming movies: $e');
      _upcomingPage--; // Quay lại trang trước nếu có lỗi
    } finally {
      _isFetchingMoreUpcoming = false;
      _safeNotifyListeners();
    }
  }

  // Drawer filter methods
  void toggleDrawerGenre(int genreId) {
    if (_selectedDrawerGenreIds.contains(genreId)) {
      _selectedDrawerGenreIds.remove(genreId);
    } else {
      _selectedDrawerGenreIds.add(genreId);
    }
    _safeNotifyListeners();
  }

  void toggleCountry(String country) {
    if (_selectedCountries.contains(country)) {
      _selectedCountries.remove(country);
    } else {
      _selectedCountries.add(country);
    }
    _safeNotifyListeners();
  }

  bool isGenreSelected(int genreId) {
    return _selectedDrawerGenreIds.contains(genreId);
  }

  bool isCountrySelected(String country) {
    return _selectedCountries.contains(country);
  }

  void clearDrawerGenres() {
    _selectedDrawerGenreIds.clear();
    _selectedCountries.clear();
    _safeNotifyListeners();
  }

  String getSelectedGenresText() {
    if (_selectedDrawerGenreIds.isEmpty && _selectedCountries.isEmpty) {
      return 'All Movies';
    }

    final genreNames = _genres
        .where((g) => _selectedDrawerGenreIds.contains(g.id))
        .map((g) => g.name)
        .toList();

    final parts = <String>[];
    if (genreNames.isNotEmpty) {
      parts.add(genreNames.join(', '));
    }
    if (_selectedCountries.isNotEmpty) {
      parts.add(_selectedCountries.join(', '));
    }

    return parts.join(' - ');
  }

  Future<List<Movie>> getMoviesByFilter() async {
    _isFilterLoading = true;
    _safeNotifyListeners();

    try {
      final genreIds = _selectedDrawerGenreIds.join(',');
      final countryCodes =
          FilterHelper.getCountryCodes(_selectedCountries.toSet());

      if (genreIds.isEmpty && countryCodes.isEmpty) {
        _isFilterLoading = false;
        _safeNotifyListeners();
        return _popularMovies;
      }

      final movies = await _apiService.discoverMovies(genreIds, countryCodes);

      _isFilterLoading = false;
      _safeNotifyListeners();
      return movies;
    } catch (e) {
      _isFilterLoading = false;
      _safeNotifyListeners();
      return [];
    }
  }

  Future<List<Movie>> getPopularTVShows() async {
    try {
      return await _apiService.getPopularTVShows();
    } catch (e) {
      debugPrint('Error fetching TV shows: $e');
      return [];
    }
  }

  // Ghi đè phương thức dispose để cập nhật cờ
  @override
  void dispose() {
    _isDisposed = true;
    _trendingRefreshTimer?.cancel(); // Hủy bộ đếm thời gian khi provider bị hủy
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    super.dispose();
  }

  // Hàm tiện ích để gọi notifyListeners một cách an toàn
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}
