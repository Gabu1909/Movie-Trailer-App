import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/models/app_notification.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/data/database_helper.dart';
import '../../core/models/movie.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/api/api_service.dart';
import 'settings_provider.dart';

import 'notification_provider.dart';

enum DownloadStatus { NotDownloaded, Downloading, Paused, Downloaded, Error }

class DownloadsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late NotificationProvider _notificationProvider;
  String? _currentUserId;
  List<Movie> _downloadedMovies = [];
  final Map<int, String> _filePaths = {};
  final Map<int, DownloadStatus> _statuses = {};
  final Map<int, double> _progress = {};
  final Map<int, CancelToken> _cancelTokens = {};
  final Map<int, String> _errorMessages = {};
  bool _isDisposed = false;

  List<Movie> get downloadedMovies => _downloadedMovies;

  DownloadsProvider({required NotificationProvider notificationProvider})
      : _notificationProvider = notificationProvider {}

  void updateDependencies(NotificationProvider notificationProvider) {
    _notificationProvider = notificationProvider;
  }

  void setUserId(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      if (userId != null) {
        loadDownloadedMovies();
      } else {
        _downloadedMovies = [];
        _filePaths.clear();
        _statuses.clear();
        notifyListeners();
      }
    }
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
    if (_currentUserId == null) {
      _downloadedMovies = [];
      _filePaths.clear();
      _statuses.clear();
      notifyListeners();
      return;
    }

    final downloadedData =
        await _dbHelper.getDownloadedMoviesWithPaths(_currentUserId!);

    final processedData = await compute(_processDownloadedData, downloadedData);

    _downloadedMovies = processedData['movies'] as List<Movie>;
    _filePaths.clear();
    _statuses.clear();
    _downloadedMovies.forEach((movie) {
      _filePaths[movie.id] =
          (processedData['filePaths'] as Map<int, String>)[movie.id]!;
      _statuses[movie.id] = DownloadStatus.Downloaded;
    });

    print('✅ Loaded ${_downloadedMovies.length} unique downloaded movies');
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

  String? getError(int movieId) {
    return _errorMessages[movieId];
  }

  Future<void> downloadMovie(Movie movie, DownloadQuality quality,
      {bool isResuming = false}) async {
    if (getStatus(movie.id) == DownloadStatus.Downloading && !isResuming)
      return;

    const Map<DownloadQuality, String> fakeVideoUrls = {
      DownloadQuality.high:
          'https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4',
      DownloadQuality.medium:
          'https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/Sample-MP4-Video-File-for-Testing.mp4',
      DownloadQuality.low:
          'https://www.sample-videos.com/video123/mp4/240/big_buck_bunny_240p_1mb.mp4',
    };

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
        final file = File(filePath);
        if (await file.exists()) {
          receivedBytes = await file.length();
        }
      }

      final options = Options(
        headers: {'Range': 'bytes=$receivedBytes-'},
      );

      await dio.download(
        url,
        filePath,
        options: options,
        cancelToken: cancelToken,
        deleteOnError: false,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final totalBytes = receivedBytes + total;
            _progress[movie.id] = (receivedBytes + received) / totalBytes;
            notifyListeners();
          }
        },
      );

      if (_currentUserId != null) {
        await _dbHelper.saveMovie(movie, _currentUserId!);
        await _dbHelper.addDownload(movie.id, filePath, _currentUserId!);
      }

      _statuses[movie.id] = DownloadStatus.Downloaded;
      _filePaths[movie.id] = filePath;

      if (!_downloadedMovies.any((m) => m.id == movie.id)) {
        _downloadedMovies.add(movie);
      }
      _errorMessages.remove(movie.id);

      final notification = AppNotification(
        id: 'download_complete_${movie.id}',
        title: 'Download Success!',
        body:
            'Movie "${movie.title}" has been downloaded and is ready to watch.',
        timestamp: DateTime.now(),
        type: NotificationType.download,
        movieId: movie.id,
      );
      _notificationProvider.addNotification(notification);

      await LocalNotificationService.showNotification(
        id: movie.id,
        title: 'Download Success!',
        body: '"${movie.title}" is ready to watch offline.',
        payload: 'movie/${movie.id}',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        debugPrint('Download for movie ${movie.id} was paused.');
        return;
      }
      _statuses[movie.id] = DownloadStatus.Error;
      debugPrint('Download error: $e');

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
    } catch (e) {
      _statuses[movie.id] = DownloadStatus.Error;
      _errorMessages[movie.id] = 'An unexpected error occurred.';
      debugPrint('Unexpected download error: $e');
    } finally {
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
      _cancelTokens[movieId]?.cancel();
      _statuses[movieId] = DownloadStatus.Paused;
      _cancelTokens.remove(movieId);
      notifyListeners();
    }
  }

  Future<void> resumeDownload(Movie movie) async {
    if (_statuses[movie.id] == DownloadStatus.Paused) {
      await downloadMovie(movie, DownloadQuality.medium, isResuming: true);
    }
  }

  Future<void> removeDownload(Movie movie) async {
    if (_currentUserId == null) return;

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
    await _dbHelper.removeDownload(movie.id, _currentUserId!);
    _downloadedMovies.removeWhere((m) => m.id == movie.id);
    _statuses.remove(movie.id);
    _filePaths.remove(movie.id);
    _errorMessages.remove(movie.id);
    _progress.remove(movie.id);
    notifyListeners();
  }

  void clearDownloads() {
    _downloadedMovies = [];
    _filePaths.clear();
    _statuses.clear();
    _currentUserId = null;
    notifyListeners();
  }
}

Map<String, dynamic> _processDownloadedData(
    List<Map<String, dynamic>> downloadedData) {
  final List<Movie> movies = [];
  final Map<int, String> filePaths = {};

  print(
      'Compute Isolate: Processing ${downloadedData.length} downloaded items.');

  for (var data in downloadedData) {
    final movie = Movie.fromMap(data);

    if (!movies.any((m) => m.id == movie.id)) {
      movies.add(movie);
      filePaths[movie.id] = data['filePath'] as String;
    } else {
      print('Compute Isolate: Duplicate movie detected: ${movie.id}');
    }
  }

  return {
    'movies': movies,
    'filePaths': filePaths,
  };
}
