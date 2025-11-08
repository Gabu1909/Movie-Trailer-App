import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/notification_item.dart';
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
        version: 8, onCreate: _createDB, onUpgrade: _onUpgrade);
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
        runtime INTEGER, -- Store runtime in minutes
        releaseDate TEXT, -- Thêm cột ngày phát hành
        dateAdded TEXT -- Thêm cột ngày thêm
      )
    ''');

    // Bảng để lưu thông tin download
    await db.execute('''
      CREATE TABLE IF NOT EXISTS downloads (
        id INTEGER PRIMARY KEY,
        filePath TEXT NOT NULL
      )
    ''');

    // Bảng mới để lưu thông báo
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        imageUrl TEXT,
        route TEXT,
        routeArgs TEXT
      )
    ''');
  }

  // Xử lý nâng cấp DB nếu cấu trúc thay đổi
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Khi nâng cấp, chỉ cần đảm bảo các bảng được tạo đúng.
    if (oldVersion < 7) {
      // Lấy thông tin của bảng 'movies' để kiểm tra các cột hiện có.
      var tableInfo = await db.rawQuery("PRAGMA table_info(movies)");

      // Kiểm tra và thêm từng cột nếu nó chưa tồn tại.
      if (!tableInfo.any((col) => col['name'] == 'mediaType')) {
        await db.execute(
            "ALTER TABLE movies ADD COLUMN mediaType TEXT NOT NULL DEFAULT 'movie'");
      }
      if (!tableInfo.any((col) => col['name'] == 'genres')) {
        await db.execute("ALTER TABLE movies ADD COLUMN genres TEXT");
      }
      if (!tableInfo.any((col) => col['name'] == 'isInWatchlist')) {
        await db.execute(
            "ALTER TABLE movies ADD COLUMN isInWatchlist INTEGER NOT NULL DEFAULT 0");
      }
      if (!tableInfo.any((col) => col['name'] == 'runtime')) {
        await db.execute("ALTER TABLE movies ADD COLUMN runtime INTEGER");
      }
      if (!tableInfo.any((col) => col['name'] == 'releaseDate')) {
        await db.execute("ALTER TABLE movies ADD COLUMN releaseDate TEXT");
      }
      if (!tableInfo.any((col) => col['name'] == 'dateAdded')) {
        await db.execute("ALTER TABLE movies ADD COLUMN dateAdded TEXT");
      }

      // Thêm bảng notifications nếu chưa có
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          isRead INTEGER NOT NULL DEFAULT 0,
          imageUrl TEXT,
          route TEXT,
          routeArgs TEXT
        )
      ''');
    }
  }

  // --- Movie Data (chung cho cả favorites và downloads) ---
  Future<void> saveMovie(Movie movie) async {
    final db = await instance.database;
    await db.insert('movies', movie.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> addFavorite(Movie movie) async {
    final db = await instance.database;
    await saveMovie(movie); // Đảm bảo phim được lưu
    await db.update('movies',
        {'isFavorite': 1, 'dateAdded': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [movie.id]);
  }

  Future<List<Movie>> getFavorites() async {
    final db = await instance.database;
    final result = await db.query('movies', where: 'isFavorite = 1');
    return result.map((json) => Movie.fromMap(json)).toList();
  }

  Future<void> removeFavorite(int id) async {
    final db = await instance.database;
    await db.update('movies', {'isFavorite': 0},
        where: 'id = ?', whereArgs: [id]);
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
    await saveMovie(movie); // Đảm bảo phim được lưu
    await db.update(
      'movies',
      {
        'isInWatchlist': isCurrentlyInWatchlist ? 0 : 1,
        'dateAdded': DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [movie.id],
    );
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

  Future<void> removeWatchlist(int id) async {
    final db = await instance.database;
    await db.update('movies', {'isInWatchlist': 0},
        where: 'id = ?', whereArgs: [id]);
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

  // Lấy thông tin chi tiết các phim đã tải và đường dẫn file trong một lần truy vấn
  Future<List<Map<String, dynamic>>> getDownloadedMoviesWithPaths() async {
    final db = await database;
    // Sử dụng INNER JOIN để kết hợp bảng 'movies' và 'downloads'
    final result = await db.rawQuery('''
      SELECT m.*, d.filePath
      FROM movies m
      INNER JOIN downloads d ON m.id = d.id
    ''');
    return result;
  }

  // --- Notifications ---
  Future<void> addNotification(NotificationItem notification) async {
    final db = await instance.database;
    await db.insert('notifications', notification.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<NotificationItem>> getNotifications() async {
    final db = await instance.database;
    final result = await db.query('notifications', orderBy: 'timestamp DESC');
    return result.map((json) => NotificationItem.fromMap(json)).toList();
  }

  Future<void> markNotificationAsRead(String id) async {
    final db = await instance.database;
    await db.update('notifications', {'isRead': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAllNotificationsAsRead() async {
    final db = await instance.database;
    await db.update('notifications', {'isRead': 1}, where: 'isRead = 0');
  }

  Future<void> deleteNotification(String id) async {
    final db = await instance.database;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllNotifications() async {
    final db = await instance.database;
    await db.delete('notifications');
  }
}
