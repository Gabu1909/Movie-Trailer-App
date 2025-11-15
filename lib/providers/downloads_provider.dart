import 'dart:io';
import 'dart:async';
import '../models/app_notification.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../data/database_helper.dart';
import '../models/movie.dart';
import '../services/local_notification_service.dart';
import 'settings_provider.dart'; // Import SettingsProvider

import 'notification_provider.dart'; // Import NotificationProvider

enum DownloadStatus { NotDownloaded, Downloading, Paused, Downloaded, Error }

class DownloadsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late NotificationProvider _notificationProvider; // Thêm NotificationProvider
  List<Movie> _downloadedMovies = [];
  final Map<int, String> _filePaths = {};
  final Map<int, DownloadStatus> _statuses = {};
  final Map<int, double> _progress = {};
  final Map<int, CancelToken> _cancelTokens = {}; // Để quản lý việc hủy tải
  final Map<int, String> _errorMessages = {}; // Thêm map để lưu lỗi
  bool _isDisposed = false;

  List<Movie> get downloadedMovies => _downloadedMovies;

  DownloadsProvider({required NotificationProvider notificationProvider})
      : _notificationProvider = notificationProvider {
    loadDownloadedMovies();
  }

  // Hàm để cập nhật dependency khi cần
  void updateDependencies(NotificationProvider notificationProvider) {
    _notificationProvider = notificationProvider;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> loadDownloadedMovies() async {
    // Tối ưu hóa: Lấy cả phim và đường dẫn file trong một truy vấn
    final downloadedData = await _dbHelper.getDownloadedMoviesWithPaths();

    _downloadedMovies.clear();
    _filePaths.clear();
    _statuses.clear();

    for (var data in downloadedData) {
      final movie = Movie.fromMap(data);
      _downloadedMovies.add(movie);
      _filePaths[movie.id] = data['filePath'] as String;
      _statuses[movie.id] = DownloadStatus.Downloaded;
    }

    notifyListeners();
  }

  DownloadStatus getStatus(int movieId) {
    return _statuses[movieId] ?? DownloadStatus.NotDownloaded;
  }

  double getProgress(int movieId) {
    return _progress[movieId] ?? 0.0;
  }

  String? getFilePath(int movieId) {
    return _filePaths[movieId];
  }

  // Hàm mới để lấy thông báo lỗi
  String? getError(int movieId) {
    return _errorMessages[movieId];
  }

  Future<void> downloadMovie(Movie movie, DownloadQuality quality,
      {bool isResuming = false}) async {
    if (getStatus(movie.id) == DownloadStatus.Downloading && !isResuming)
      return;

    // Map chất lượng với URL giả
    const Map<DownloadQuality, String> fakeVideoUrls = {
      DownloadQuality.high:
          'https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4', // 10MB
      DownloadQuality.medium:
          'https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/Sample-MP4-Video-File-for-Testing.mp4', // 5MB
      DownloadQuality.low:
          'https://www.sample-videos.com/video123/mp4/240/big_buck_bunny_240p_1mb.mp4', // 1MB
    };

    // Lấy URL dựa trên chất lượng đã chọn
    final url =
        fakeVideoUrls[quality] ?? fakeVideoUrls[DownloadQuality.medium]!;

    _statuses[movie.id] = DownloadStatus.Downloading;
    if (!isResuming) {
      _progress[movie.id] = 0.0;
    }
    notifyListeners();

    final dio = Dio();
    final cancelToken = CancelToken();
    _cancelTokens[movie.id] = cancelToken;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${movie.id}.mp4';

      int receivedBytes = 0;
      if (isResuming) {
        // Lấy số byte đã tải từ file hiện có
        final file = File(filePath);
        if (await file.exists()) {
          receivedBytes = await file.length();
        }
      }

      final options = Options(
        headers: {'Range': 'bytes=$receivedBytes-'}, // Header để tiếp tục tải
      );

      await dio.download(
        url,
        filePath,
        options: options,
        cancelToken: cancelToken,
        deleteOnError: false, // Rất quan trọng: không xóa file khi bị hủy
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Nếu tiếp tục tải, total từ server có thể là phần còn lại
            // nên ta cần tính toán lại tổng dung lượng
            final totalBytes = receivedBytes + total;
            _progress[movie.id] = (receivedBytes + received) / totalBytes;
            notifyListeners();
          }
        },
      );

      // Save to DB after download completes
      await _dbHelper.saveMovie(movie);
      await _dbHelper.addDownload(movie.id, filePath);

      _statuses[movie.id] = DownloadStatus.Downloaded;
      _filePaths[movie.id] = filePath;
      _downloadedMovies.add(movie);
      _errorMessages.remove(movie.id); // Xóa lỗi cũ nếu có

      // Gửi thông báo khi tải xong
      final notification = AppNotification(
        id: 'download_complete_${movie.id}',
        title: 'Tải thành công!',
        body: 'Phim "${movie.title}" đã được tải xong và sẵn sàng để xem.',
        timestamp: DateTime.now(),
        type: NotificationType.download,
        movieId: movie.id,
      );
      _notificationProvider.addNotification(notification);

      // Hiển thị thông báo cục bộ
      await LocalNotificationService.showNotification(
        id: movie.id,
        title: 'Download Complete',
        body: '"${movie.title}" has been downloaded successfully.',
      );
    } on DioException catch (e) {
      // Nếu lỗi là do người dùng chủ động hủy (tạm dừng) thì không làm gì cả
      if (e.type == DioExceptionType.cancel) {
        debugPrint('Download for movie ${movie.id} was paused.');
        return; // Thoát khỏi hàm, trạng thái đã được set là Paused ở hàm pauseDownload
      }
      // Xử lý các lỗi khác
      _statuses[movie.id] = DownloadStatus.Error;
      debugPrint('Download error: $e');
      _errorMessages[movie.id] = 'An error occurred.';

      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          _errorMessages[movie.id] =
              'Connection timed out. Please check your network.';
        } else if (e.type == DioExceptionType.badResponse) {
          _errorMessages[movie.id] =
              'Failed to download. Server returned an error.';
        } else {
          _errorMessages[movie.id] = 'A network error occurred.';
        }
      } else {
        _errorMessages[movie.id] = 'An unknown error occurred during download.';
      }
    } catch (e) {
      _statuses[movie.id] = DownloadStatus.Error;
      _errorMessages[movie.id] = 'An unexpected error occurred.';
      debugPrint('Unexpected download error: $e');
    } finally {
      // Chỉ xóa progress nếu tải xong hoặc lỗi, không xóa khi tạm dừng
      if (_statuses[movie.id] != DownloadStatus.Paused) {
        _progress.remove(movie.id);
      }
      _cancelTokens.remove(movie.id);
      notifyListeners();
    }
  }

  Future<void> pauseDownload(int movieId) async {
    if (_statuses[movieId] == DownloadStatus.Downloading &&
        _cancelTokens.containsKey(movieId)) {
      _cancelTokens[movieId]?.cancel(); // Gửi yêu cầu hủy
      _statuses[movieId] = DownloadStatus.Paused;
      _cancelTokens.remove(movieId);
      notifyListeners();
    }
  }

  Future<void> resumeDownload(Movie movie) async {
    if (_statuses[movie.id] == DownloadStatus.Paused) {
      // Khi resume, chúng ta không cần biết chất lượng nữa vì file đã có
      // Gọi lại hàm downloadMovie với cờ isResuming = true
      await downloadMovie(movie, DownloadQuality.medium,
          isResuming: true); // Quality không quan trọng khi resume
    }
  }

  Future<void> removeDownload(Movie movie) async {
    final filePath = getFilePath(movie.id);
    if (filePath != null) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
    }
    await _dbHelper.removeDownload(movie.id);
    _downloadedMovies.removeWhere((m) => m.id == movie.id);
    _statuses.remove(movie.id);
    _filePaths.remove(movie.id);
    _errorMessages.remove(movie.id); // Cũng xóa thông báo lỗi khi xóa phim
    _progress.remove(movie.id); // Xóa progress khi xóa phim
    notifyListeners();
  }
}
