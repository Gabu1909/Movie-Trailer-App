class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  CacheEntry(this.data) : timestamp = DateTime.now();

  bool isExpired(Duration maxAge) =>
      DateTime.now().difference(timestamp) > maxAge;
}
