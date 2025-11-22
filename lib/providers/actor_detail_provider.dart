import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/models/actor_detail.dart';
import 'cache_entry.dart';

class ActorDetailProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  static const _cacheTTL = Duration(minutes: 30);
  static const int _maxCacheSize = 50;

  final Map<int, CacheEntry<ActorDetail>> _actorCache = {};
  final List<int> _accessOrder = [];

  final Map<int, bool> _loadingStatus = {};
  final Map<int, String?> _errorMessages = {};

  ActorDetail? getActor(int actorId) => _actorCache[actorId]?.data;
  bool isLoading(int actorId) {
    if (_actorCache.containsKey(actorId)) {
      _markAsRecentlyUsed(actorId);
    }
    return _loadingStatus[actorId] ?? true;
  }

  String? getError(int actorId) => _errorMessages[actorId];

  Future<void> fetchActorDetails(int actorId,
      {bool forceRefresh = false}) async {
    final cachedEntry = _actorCache[actorId];

    if (!forceRefresh &&
        cachedEntry != null &&
        !cachedEntry.isExpired(_cacheTTL)) {
      if (_loadingStatus[actorId] == true) {
        _loadingStatus[actorId] = false;
        _markAsRecentlyUsed(actorId);
        notifyListeners();
      }
      return;
    }

    _loadingStatus[actorId] = true;
    _errorMessages.remove(actorId);
    notifyListeners();

    try {
      final actorDetail = await _apiService.getActorDetails(actorId);
      _evictIfNeeded();
      _actorCache[actorId] = CacheEntry(actorDetail);
      _loadingStatus[actorId] = false;
      _markAsRecentlyUsed(actorId);
      notifyListeners();
    } catch (e) {
      _errorMessages[actorId] =
          'Failed to load actor details. Please try again.';
      _loadingStatus[actorId] = false;
      notifyListeners();
      debugPrint('Error fetching actor details for $actorId: $e');
    }
  }

  void clearCache() {
    _actorCache.clear();
    _loadingStatus.clear();
    _errorMessages.clear();
    _accessOrder.clear();
    notifyListeners();
    debugPrint("ActorDetailProvider cache cleared.");
  }

  void _markAsRecentlyUsed(int actorId) {
    _accessOrder.remove(actorId);
    _accessOrder.add(actorId);
  }

  void _evictIfNeeded() {
    if (_actorCache.length < _maxCacheSize) {
      return;
    }

    final int lruActorId = _accessOrder.first;

    _actorCache.remove(lruActorId);
    _accessOrder.remove(lruActorId);
    _loadingStatus.remove(lruActorId);
    _errorMessages.remove(lruActorId);

    debugPrint("Cache eviction: Removed actor with ID $lruActorId");
  }
}
