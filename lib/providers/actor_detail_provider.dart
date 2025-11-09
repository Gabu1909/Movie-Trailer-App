import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/actor_detail.dart';
import 'cache_entry.dart'; // Import lớp CacheEntry

class ActorDetailProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Thời gian cache tồn tại, ví dụ: 30 phút
  static const _cacheTTL = Duration(minutes: 30);
  // Giới hạn số lượng diễn viên được cache để tránh sử dụng quá nhiều bộ nhớ.
  static const int _maxCacheSize = 50;

  // Cache để lưu trữ chi tiết diễn viên đã tải
  final Map<int, CacheEntry<ActorDetail>> _actorCache = {};
  // Danh sách để theo dõi thứ tự sử dụng (LRU). Key ở cuối là được dùng gần nhất.
  final List<int> _accessOrder = [];

  // Trạng thái tải và lỗi cho từng actorId
  final Map<int, bool> _loadingStatus = {};
  final Map<int, String?> _errorMessages = {};

  // Getters để UI truy cập
  ActorDetail? getActor(int actorId) => _actorCache[actorId]?.data;
  bool isLoading(int actorId) {
    // Khi truy cập, cập nhật lại thứ tự sử dụng
    if (_actorCache.containsKey(actorId)) {
      _markAsRecentlyUsed(actorId);
    }
    return _loadingStatus[actorId] ?? true;
  }

  String? getError(int actorId) => _errorMessages[actorId];

  Future<void> fetchActorDetails(int actorId,
      {bool forceRefresh = false}) async {
    final cachedEntry = _actorCache[actorId];

    // 1. Kiểm tra cache: nếu không force refresh và có cache hợp lệ, không tải lại.
    if (!forceRefresh &&
        cachedEntry != null &&
        !cachedEntry.isExpired(_cacheTTL)) {
      // Nếu đang loading thì set lại là false, còn không thì thôi.
      if (_loadingStatus[actorId] == true) {
        _loadingStatus[actorId] = false;
        // Đánh dấu là vừa được sử dụng
        _markAsRecentlyUsed(actorId);
        notifyListeners();
      }
      return;
    }

    // 2. Đánh dấu là đang tải (hoặc tải lại nếu cache đã hết hạn)
    _loadingStatus[actorId] = true;
    _errorMessages.remove(actorId); // Xóa lỗi cũ
    notifyListeners();

    try {
      // 3. Gọi API
      final actorDetail = await _apiService.getActorDetails(actorId);
      // 4. Lưu vào cache với timestamp mới
      _evictIfNeeded(); // Kiểm tra và xóa cache nếu cần trước khi thêm mới
      _actorCache[actorId] = CacheEntry(actorDetail);
      _loadingStatus[actorId] = false;
      // Đánh dấu là vừa được sử dụng
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

  /// Xóa cache khi cần thiết (ví dụ: khi bộ nhớ thấp)
  void clearCache() {
    _actorCache.clear();
    _loadingStatus.clear();
    _errorMessages.clear();
    _accessOrder.clear();
    notifyListeners();
    debugPrint("ActorDetailProvider cache cleared.");
  }

  /// Đánh dấu một actorId là vừa được sử dụng bằng cách di chuyển nó lên cuối danh sách.
  void _markAsRecentlyUsed(int actorId) {
    _accessOrder.remove(actorId);
    _accessOrder.add(actorId);
  }

  /// Kiểm tra và xóa bớt cache nếu vượt quá giới hạn.
  void _evictIfNeeded() {
    // Nếu cache chưa đầy, không cần làm gì.
    if (_actorCache.length < _maxCacheSize) {
      return;
    }

    // Nếu cache đã đầy, lấy actorId ít được sử dụng nhất (ở đầu danh sách).
    final int lruActorId = _accessOrder.first;

    // Xóa khỏi tất cả các map liên quan.
    _actorCache.remove(lruActorId);
    _accessOrder.remove(lruActorId);
    _loadingStatus.remove(lruActorId);
    _errorMessages.remove(lruActorId);

    debugPrint("Cache eviction: Removed actor with ID $lruActorId");
  }
}
