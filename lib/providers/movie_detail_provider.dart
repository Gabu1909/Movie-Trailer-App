import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/user.dart';
import '../data/database_helper.dart';
import '../models/movie.dart';
import '../models/review.dart';
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

  // Cache để lưu trữ reviews
  final Map<int, CacheEntry<List<Review>>> _reviewsCache = {};
  final Map<int, Review?> _userReviewsCache = {};
  final List<int> _accessOrder = [];

  // Trạng thái tải và lỗi cho từng movieId
  final Map<int, bool> _loadingStatus = {};
  final Map<int, bool> _reviewsLoadingStatus =
      {}; // Trạng thái tải riêng cho reviews
  final Map<int, String?> _errorMessages = {};
  // Cờ để theo dõi xem review đã được fetch lần đầu chưa
  final Map<int, bool> _reviewsFetched = {};

  // Getters để UI truy cập
  Movie? getMovie(int movieId) => _movieCache[movieId]?.data;
  bool isReviewsLoading(int movieId) => _reviewsLoadingStatus[movieId] ?? false;
  bool isLoading(int movieId) {
    // Khi truy cập, cập nhật lại thứ tự sử dụng
    if (_movieCache.containsKey(movieId)) {
      _markAsRecentlyUsed(movieId);
    }
    return _loadingStatus[movieId] ?? true;
  }

  String? getError(int movieId) => _errorMessages[movieId];

  List<Review> getReviews(int movieId) => _reviewsCache[movieId]?.data ?? [];

  Review? getUserReview(int movieId) => _userReviewsCache[movieId];

  // Getter để kiểm tra xem review đã được fetch chưa
  bool haveReviewsBeenFetched(int movieId) => _reviewsFetched[movieId] ?? false;

  Future<void> fetchMovieDetails(int movieId,
      {bool forceRefresh = false, User? currentUser}) async {
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

      // Thêm dòng này để đảm bảo UI được cập nhật sau khi fetch xong
      // và trước khi notifyListeners() được gọi.
      _errorMessages.remove(movieId);
      notifyListeners();
    } catch (e) {
      _errorMessages[movieId] =
          'Failed to load movie details. Please try again.';
      _loadingStatus[movieId] = false;
      notifyListeners();
      debugPrint('Error fetching movie details for $movieId: $e');
    }
  }

  Future<void> fetchMovieReviews(int movieId,
      {bool forceRefresh = false, User? currentUser}) async {
    final cachedEntry = _reviewsCache[movieId];
    final alreadyFetched = haveReviewsBeenFetched(movieId);

    // Chỉ fetch nếu forceRefresh hoặc chưa fetch lần nào.
    if (!forceRefresh && alreadyFetched && cachedEntry != null && !cachedEntry.isExpired(_cacheTTL)) {
      return;
    }

    _reviewsLoadingStatus[movieId] = true;
    notifyListeners();

    try {
      // 2. Gọi API để lấy review từ TMDB và review của user từ DB
      final reviews = await _apiService.getMovieReviews(movieId);
      final userReview = await DatabaseHelper.instance.getUserReview(movieId);

      // 3. Lưu vào cache
      _reviewsCache[movieId] = CacheEntry(reviews);
      _userReviewsCache[movieId] = userReview;
      _reviewsFetched[movieId] = true; // Đánh dấu là đã fetch
    } catch (e) {
      debugPrint('Error fetching movie reviews for $movieId: $e');
    } finally {
      _reviewsLoadingStatus[movieId] = false;
      notifyListeners();
    }
  }

  Future<void> saveUserReview(
      int movieId, double rating, String content, {User? currentUser}) async {
    await DatabaseHelper.instance.saveUserReview(movieId, rating, content, currentUser?.name, currentUser?.profileImageUrl);
    // Fetch lại review của user và cập nhật cache
    final userReview = await DatabaseHelper.instance.getUserReview(movieId);
    _userReviewsCache[movieId] = userReview;
    notifyListeners();
  }

  Future<void> deleteUserReview(int movieId) async {
    await DatabaseHelper.instance.deleteUserReview(movieId);
    // Xóa review khỏi cache và cập nhật UI
    _userReviewsCache.remove(movieId);
    notifyListeners();
  }

  void _markAsRecentlyUsed(int movieId) {
    _accessOrder.remove(movieId);
    _accessOrder.add(movieId);
  }

  void _evictIfNeeded() {
    if (_movieCache.length < _maxCacheSize) return;
    final int lruMovieId = _accessOrder.first;
    _movieCache.remove(lruMovieId);
    _reviewsCache.remove(lruMovieId);
    _userReviewsCache.remove(lruMovieId);
    _accessOrder.remove(lruMovieId);
    _reviewsFetched.remove(lruMovieId); // Xóa cờ fetch review
    _loadingStatus.remove(lruMovieId);
    _errorMessages.remove(lruMovieId);
    debugPrint("Cache eviction: Removed movie with ID $lruMovieId");
  }
}
