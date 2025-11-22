class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException (${statusCode}): $message';
    }
    return 'ApiException: $message';
  }

  String get userMessage {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please try again.';
      case 401:
        return 'Authentication failed. Please log in again.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Content not found.';
      case 408:
        return 'Connection timeout. Please check your internet.';
      case 429:
        return 'Too many requests. Please wait a moment.';
      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';
      default:
        return message;
    }
  }
}

class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;

  DatabaseException(this.message, {this.originalError});

  @override
  String toString() => 'DatabaseException: $message';
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';

  String get userMessage =>
      'No internet connection. Please check your network.';
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';

  String get userMessage => 'Request timed out. Please try again.';
}

class ParseException implements Exception {
  final String message;
  final dynamic originalError;

  ParseException(this.message, {this.originalError});

  @override
  String toString() => 'ParseException: $message';

  String get userMessage => 'Failed to process data. Please try again.';
}
