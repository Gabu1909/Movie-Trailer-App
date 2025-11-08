// Tạo file mới: d:/Project_Group_Movies/lib/providers/downloads_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../data/database_helper.dart';
import '../models/movie.dart';

enum DownloadStatus { NotDownloaded, Downloading, Downloaded, Error }

class DownloadsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Dio _dio = Dio();

  // Trạng thái tải tức thời
  final Map<int, DownloadStatus> _downloadStatus = {};
  final Map<int, double> _progress = {};

  // Danh sách phim đã tải (lấy từ DB)
  List<Movie> _downloadedMovies = [];
  Map<int, String> _downloadedFilePaths = {};

  List<Movie> get downloadedMovies => _downloadedMovies;
  DownloadStatus getStatus(int movieId) =>
      _downloadStatus[movieId] ??
      (_downloadedFilePaths.containsKey(movieId)
          ? DownloadStatus.Downloaded
          : DownloadStatus.NotDownloaded);
  double getProgress(int movieId) => _progress[movieId] ?? 0.0;
  String? getFilePath(int movieId) => _downloadedFilePaths[movieId];

  DownloadsProvider() {
    loadDownloadedMovies();
  }

  Future<void> loadDownloadedMovies() async {
    _downloadedFilePaths = await _dbHelper.getDownloadedFilePaths();
    final movieIds = _downloadedFilePaths.keys.toList();

    // Sử dụng hàm mới để lấy chi tiết các phim đã tải
    _downloadedMovies = await _dbHelper.getDownloadedMovies(movieIds);
    notifyListeners();
  }

  Future<void> downloadMovie(Movie movie, String videoUrl) async {
    if (getStatus(movie.id) == DownloadStatus.Downloading) return;

    _downloadStatus[movie.id] = DownloadStatus.Downloading;
    _progress[movie.id] = 0.0;
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/movie_${movie.id}.mp4';

      await _dio.download(
        videoUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _progress[movie.id] = received / total;
            notifyListeners();
          }
        },
      );

      // Lưu thông tin phim và thông tin download vào DB
      await _dbHelper.saveMovie(movie); // Lưu metadata phim vào bảng 'movies'
      await _dbHelper.addDownload(movie.id, savePath);

      _downloadStatus[movie.id] = DownloadStatus.Downloaded;
      await loadDownloadedMovies(); // Tải lại danh sách
    } catch (e) {
      _downloadStatus[movie.id] = DownloadStatus.Error;
      notifyListeners();
    }
  }

  Future<void> removeDownload(Movie movie) async {
    final filePath = getFilePath(movie.id);
    if (filePath == null) return;

    // Xóa khỏi DB
    await _dbHelper.removeDownload(movie.id);

    // Xóa file vật lý
    try {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } catch (e) {/* Xử lý lỗi xóa file */}

    await loadDownloadedMovies(); // Tải lại danh sách
  }
}
