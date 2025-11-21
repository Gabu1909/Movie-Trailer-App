import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/user_review_with_movie.dart';

class MyReviewsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<UserReviewWithMovie> _reviews = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const _pageSize = 15;
  String? _error;

  List<UserReviewWithMovie> get reviews => _reviews;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get error => _error;

  Future<void> loadMyReviews(String userId, {bool isRefresh = false}) async {
    if (isRefresh) {
      _reviews = [];
      _page = 0;
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newReviews = await _dbHelper.getAllUserReviews(userId,
          limit: _pageSize, offset: 0);
      _reviews = newReviews;
      if (newReviews.length < _pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      _error = "Failed to load your reviews. Please try again.";
      debugPrint("Error loading user reviews: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMore(String userId) async {
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      _page++;
      final newReviews = await _dbHelper.getAllUserReviews(userId,
          limit: _pageSize, offset: _page * _pageSize);
      if (newReviews.length < _pageSize) {
        _hasMore = false;
      }
      _reviews.addAll(newReviews);
    } catch (e) {
      _page--; // Rollback page number on error
      debugPrint("Error fetching more reviews: $e");
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }
}
