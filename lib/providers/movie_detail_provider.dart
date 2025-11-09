import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/movie.dart';
import 'cache_entry.dart'; // Import lớp CacheEntry

class MovieDetailProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Thời gian cache tồn tại, ví dụ: 30 phút
  static const _cacheTTL = Duration(minutes: 30);
  // Giới hạn số lượng phim được cache để tránh sử dụng quá nhiều bộ nhớ.
  static const int _maxCacheSize = 50;

  // Cache để lưu trữ chi tiết phim đã tải
  final Map<int, CacheEntry<Movie>> _movieCache = {};
  // Danh sách để theo dõi thứ tự sử dụng (LRU). Key ở cuối là được dùng gần nhất.
  final List<int> _accessOrder = [];

  // Trạng thái tải và lỗi cho từng movieId
  final Map<int, bool> _loadingStatus = {};
  final Map<int, String?> _errorMessages = {};

  // Getters để UI truy cập
  Movie? getMovie(int movieId) => _movieCache[movieId]?.data;
  bool isLoading(int movieId) {
    // Khi truy cập, cập nhật lại thứ tự sử dụng
    if (_movieCache.containsKey(movieId)) {
      _markAsRecentlyUsed(movieId);
    }
    return _loadingStatus[movieId] ?? true;
  }

  String? getError(int movieId) => _errorMessages[movieId];

  Future<void> fetchMovieDetails(int movieId,
      {bool forceRefresh = false}) async {
    final cachedEntry = _movieCache[movieId];

    // 1. Kiểm tra cache: nếu không force refresh và có cache hợp lệ, không tải lại.
    if (!forceRefresh &&
        cachedEntry != null &&
        !cachedEntry.isExpired(_cacheTTL)) {
      if (_loadingStatus[movieId] == true) {
        _loadingStatus[movieId] = false;
        _markAsRecentlyUsed(movieId);
        notifyListeners();
      }
      return;
    }

    // 2. Đánh dấu là đang tải
    _loadingStatus[movieId] = true;
    _errorMessages.remove(movieId);
    notifyListeners();

    try {
      // 3. Gọi API
      final movieDetail = await _apiService.getMovieDetail(movieId);
      // 4. Lưu vào cache
      _evictIfNeeded();
      _movieCache[movieId] = CacheEntry(movieDetail);
      _loadingStatus[movieId] = false;
      _markAsRecentlyUsed(movieId);
      notifyListeners();
    } catch (e) {
      _errorMessages[movieId] =
          'Failed to load movie details. Please try again.';
      _loadingStatus[movieId] = false;
      notifyListeners();
      debugPrint('Error fetching movie details for $movieId: $e');
    }
  }

  void _markAsRecentlyUsed(int movieId) {
    _accessOrder.remove(movieId);
    _accessOrder.add(movieId);
  }

  void _evictIfNeeded() {
    if (_movieCache.length < _maxCacheSize) return;
    final int lruMovieId = _accessOrder.first;
    _movieCache.remove(lruMovieId);
    _accessOrder.remove(lruMovieId);
    _loadingStatus.remove(lruMovieId);
    _errorMessages.remove(lruMovieId);
    debugPrint("Cache eviction: Removed movie with ID $lruMovieId");
  }
}
