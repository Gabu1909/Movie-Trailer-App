import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/models/user.dart';
import '../../core/data/database_helper.dart';
import '../../core/models/movie.dart';
import '../../core/models/review.dart';
import 'cache_entry.dart';

class MovieDetailProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  static const _cacheTTL = Duration(minutes: 30);
  static const int _maxCacheSize = 50;

  final Map<int, CacheEntry<Movie>> _movieCache = {};
  final Map<int, CacheEntry<List<Review>>> _reviewsCache = {};
  final Map<int, Review?> _userReviewsCache = {};
  final List<int> _accessOrder = [];

  final Map<int, bool> _loadingStatus = {};
  final Map<int, bool> _reviewsLoadingStatus = {};
  final Map<int, String?> _errorMessages = {};
  final Map<int, bool> _reviewsFetched = {};

  Movie? getMovie(int movieId) => _movieCache[movieId]?.data;
  bool isReviewsLoading(int movieId) => _reviewsLoadingStatus[movieId] ?? false;
  bool isLoading(int movieId) {
    if (_movieCache.containsKey(movieId)) {
      _markAsRecentlyUsed(movieId);
    }
    return _loadingStatus[movieId] ?? true;
  }

  String? getError(int movieId) => _errorMessages[movieId];

  List<Review> getReviews(int movieId) => _reviewsCache[movieId]?.data ?? [];

  Review? getUserReview(int movieId) => _userReviewsCache[movieId];

  bool haveReviewsBeenFetched(int movieId) => _reviewsFetched[movieId] ?? false;

  Future<void> fetchMovieDetails(int movieId,
      {bool forceRefresh = false,
      User? currentUser,
      String contentType = 'movie'}) async {
    final cachedEntry = _movieCache[movieId];

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

    _loadingStatus[movieId] = true;
    _errorMessages.remove(movieId);
    notifyListeners();

    try {
      final movieDetail = contentType == 'tv'
          ? await _apiService.getTvShowDetail(movieId)
          : await _apiService.getMovieDetail(movieId);

      _evictIfNeeded();
      _movieCache[movieId] = CacheEntry(movieDetail);

      _loadingStatus[movieId] = false;
      _markAsRecentlyUsed(movieId);

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

    if (!forceRefresh &&
        alreadyFetched &&
        cachedEntry != null &&
        !cachedEntry.isExpired(_cacheTTL)) {
      return;
    }

    _reviewsLoadingStatus[movieId] = true;
    notifyListeners();

    try {
      final reviews = await _apiService.getMovieReviews(movieId);
      final userId = currentUser?.id ?? 'guest';
      final userReview =
          await DatabaseHelper.instance.getUserReview(movieId, userId);

      _reviewsCache[movieId] = CacheEntry(reviews);
      _userReviewsCache[movieId] = userReview;
      _reviewsFetched[movieId] = true;
    } catch (e) {
      debugPrint('Error fetching movie reviews for $movieId: $e');
    } finally {
      _reviewsLoadingStatus[movieId] = false;
      notifyListeners();
    }
  }

  Future<void> saveUserReview(int movieId, double rating, String content,
      {User? currentUser}) async {
    final userId = currentUser?.id ?? 'guest';
    
    // Auto-save movie info to database if not already saved
    // This ensures the movie exists in database for "My Reviews" to work
    final movieEntry = _movieCache[movieId];
    if (movieEntry != null) {
      await DatabaseHelper.instance.saveMovie(movieEntry.data, userId);
      print('✅ Auto-saved movie info to database for review');
    }
    
    await DatabaseHelper.instance.saveUserReview(movieId, userId, rating,
        content, currentUser?.name, currentUser?.profileImageUrl);
    final userReview =
        await DatabaseHelper.instance.getUserReview(movieId, userId);
    _userReviewsCache[movieId] = userReview;
    notifyListeners();
  }

  Future<void> deleteUserReview(int movieId, {User? currentUser}) async {
    final userId = currentUser?.id ?? 'guest';
    print(
        '🗑️ Attempting to delete review - movieId: $movieId, userId: $userId, userName: ${currentUser?.name}');
    await DatabaseHelper.instance.deleteUserReview(movieId, userId);
    _userReviewsCache.remove(movieId);
    _reviewsCache.remove(movieId);
    notifyListeners();
    print('✅ Review deleted and cache cleared');
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
    _reviewsFetched.remove(lruMovieId);
    _loadingStatus.remove(lruMovieId);
    _errorMessages.remove(lruMovieId);
    debugPrint("Cache eviction: Removed movie with ID $lruMovieId");
  }
}
