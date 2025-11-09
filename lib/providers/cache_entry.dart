/// Một lớp generic để bọc dữ liệu cache cùng với thời gian lưu trữ.
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  CacheEntry(this.data) : timestamp = DateTime.now();

  /// Kiểm tra xem cache có hết hạn hay không.
  bool isExpired(Duration maxAge) =>
      DateTime.now().difference(timestamp) > maxAge;
}
