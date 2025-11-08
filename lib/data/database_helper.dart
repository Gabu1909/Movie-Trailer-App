import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/movie.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('favorites.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // Tăng version lên 2 để kích hoạt onUpgrade nếu cần
    return await openDatabase(path,
        version: 5, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    // Bảng để lưu thông tin chung của phim (tránh trùng lặp)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS movies (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        overview TEXT NOT NULL,
        posterPath TEXT,
        voteAverage REAL NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        isInWatchlist INTEGER NOT NULL DEFAULT 0, -- Thêm cột mới
        mediaType TEXT NOT NULL DEFAULT 'movie', -- Thêm cột mediaType
        genres TEXT,
        runtime INTEGER -- Store runtime in minutes
      )
    ''');

    // Bảng để lưu thông tin download
    await db.execute('''
      CREATE TABLE IF NOT EXISTS downloads (
        id INTEGER PRIMARY KEY,
        filePath TEXT NOT NULL
      )
    ''');
  }

  // Xử lý nâng cấp DB nếu cấu trúc thay đổi
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Khi nâng cấp, chỉ cần đảm bảo các bảng được tạo đúng.
    await _createDB(db, newVersion);
  }

  // --- Movie Data (chung cho cả favorites và downloads) ---
  Future<void> saveMovie(Movie movie) async {
    final db = await instance.database;
    await db.insert('movies', movie.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }


  Future<void> addFavorite(Movie movie) async {
    final db = await instance.database;
    final movieWithFavorite = movie.copyWith(isFavorite: true);
    await db.insert('movies', movieWithFavorite.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Movie>> getFavorites() async {
    final db = await instance.database;
    final result = await db.query('movies', where: 'isFavorite = 1');
    return result.map((json) => Movie.fromMap(json)).toList();
  }

  Future<void> removeFavorite(Movie movie) async {
    final db = await instance.database;
    final movieWithFavoriteRemoved = movie.copyWith(isFavorite: false);
    await db.insert('movies', movieWithFavoriteRemoved.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> isFavorite(int id) async {
    final db = await instance.database;
    final result = await db
        .query('movies', where: 'id = ? AND isFavorite = 1', whereArgs: [id]);
    return result.isNotEmpty;
  }

  // --- Watchlist ---
  Future<void> toggleWatchlist(Movie movie) async {
    final db = await instance.database;
    final isCurrentlyInWatchlist = await isInWatchlist(movie.id);
    final movieWithWatchlist =
        movie.copyWith(isInWatchlist: !isCurrentlyInWatchlist);
    await db.insert('movies', movieWithWatchlist.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Movie>> getWatchlist() async {
    final db = await instance.database;
    final result = await db.query('movies', where: 'isInWatchlist = 1');
    return result.map((json) => Movie.fromMap(json)).toList();
  }

  Future<bool> isInWatchlist(int id) async {
    final db = await instance.database;
    final result = await db.query('movies',
        where: 'id = ? AND isInWatchlist = 1', whereArgs: [id]);
    return result.isNotEmpty;
  }

  // --- Downloads ---
  Future<void> addDownload(int movieId, String filePath) async {
    final db = await database;
    await db.insert('downloads', {'id': movieId, 'filePath': filePath},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeDownload(int movieId) async {
    final db = await database;
    await db.delete('downloads', where: 'id = ?', whereArgs: [movieId]);
  }

  // Lấy thông tin các phim đã tải
  Future<Map<int, String>> getDownloadedFilePaths() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('downloads');
    return {for (var e in result) e['id'] as int: e['filePath'] as String};
  }

  // Lấy thông tin chi tiết các phim đã tải từ bảng 'movies'
  Future<List<Movie>> getDownloadedMovies(List<int> movieIds) async {
    if (movieIds.isEmpty) return [];
    final db = await database;
    final result =
        await db.query('movies', where: 'id IN (${movieIds.join(',')})');
    return result.map((json) => Movie.fromMap(json)).toList();
  }

  /// Fetches a single movie from the DB to check its status,
  /// then returns a new Movie object with the combined data.
  Future<Movie> getMovieWithLocalStatus(Movie movieFromApi) async {
    final db = await instance.database;
    final result =
        await db.query('movies', where: 'id = ?', whereArgs: [movieFromApi.id]);

    if (result.isNotEmpty) {
      final localData = result.first;
      return movieFromApi.copyWith(
        isFavorite: localData['isFavorite'] == 1,
        isInWatchlist: localData['isInWatchlist'] == 1,
      );
    }
    return movieFromApi; // Return the API movie if not in DB
  }
}
