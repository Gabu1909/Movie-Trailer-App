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
    // Tăng version lên 15 để clean duplicate downloads
    return await openDatabase(path,
        version: 15, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    // Bảng để lưu thông tin chung của phim với composite primary key (id, userId)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS movies (
        id INTEGER NOT NULL,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        overview TEXT NOT NULL,
        posterPath TEXT,
        voteAverage REAL NOT NULL,
        voteCount INTEGER NOT NULL DEFAULT 0,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        isInWatchlist INTEGER NOT NULL DEFAULT 0,
        mediaType TEXT NOT NULL DEFAULT 'movie',
        genres TEXT,
        runtime INTEGER,
        releaseDate TEXT,
        dateAdded TEXT,
        trailerKey TEXT,
        PRIMARY KEY (id, userId)
      )
    ''');

    // Bảng để lưu thông tin download với composite primary key
    await db.execute('''
      CREATE TABLE IF NOT EXISTS downloads (
        id INTEGER NOT NULL,
        userId TEXT NOT NULL,
        filePath TEXT NOT NULL,
        PRIMARY KEY (id, userId)
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

    // ⚡ Create indexes for optimization
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_movies_userId ON movies(userId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_movies_dateAdded ON movies(dateAdded)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_downloads_userId ON downloads(userId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_timestamp ON notifications(timestamp)');
    print('✅ Database indexes created');
  }

  // Xử lý nâng cấp DB nếu cấu trúc thay đổi
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Database upgrade from version $oldVersion to $newVersion');

    // Version 13: Rebuild database với composite primary key
    if (oldVersion < 13) {
      print('🔨 Rebuilding database with composite primary key...');

      // 1. Backup data từ movies table
      List<Map<String, dynamic>> moviesBackup = [];
      try {
        moviesBackup = await db.query('movies');
        print('📦 Backed up ${moviesBackup.length} movies');
      } catch (e) {
        print('⚠️ No existing movies table or error: $e');
      }

      // 2. Backup data từ downloads table
      List<Map<String, dynamic>> downloadsBackup = [];
      try {
        downloadsBackup = await db.query('downloads');
        print('📦 Backed up ${downloadsBackup.length} downloads');
      } catch (e) {
        print('⚠️ No existing downloads table or error: $e');
      }

      // 3. Drop old tables
      await db.execute('DROP TABLE IF EXISTS movies');
      await db.execute('DROP TABLE IF EXISTS downloads');
      print('🗑️ Dropped old tables');

      // 4. Create new tables with composite key
      await db.execute('''
        CREATE TABLE movies (
          id INTEGER NOT NULL,
          userId TEXT NOT NULL,
          title TEXT NOT NULL,
          overview TEXT NOT NULL,
          posterPath TEXT,
          voteAverage REAL NOT NULL,
          voteCount INTEGER NOT NULL DEFAULT 0,
          isFavorite INTEGER NOT NULL DEFAULT 0,
          isInWatchlist INTEGER NOT NULL DEFAULT 0,
          mediaType TEXT NOT NULL DEFAULT 'movie',
          genres TEXT,
          runtime INTEGER,
          releaseDate TEXT,
          dateAdded TEXT,
          trailerKey TEXT,
          PRIMARY KEY (id, userId)
        )
      ''');

      await db.execute('''
        CREATE TABLE downloads (
          id INTEGER NOT NULL,
          userId TEXT NOT NULL,
          filePath TEXT NOT NULL,
          PRIMARY KEY (id, userId)
        )
      ''');
      print('✅ Created new tables with composite primary key');

      // 5. Restore data với userId (nếu có)
      for (var movie in moviesBackup) {
        try {
          // Đảm bảo có userId, nếu không thì dùng 'guest'
          if (!movie.containsKey('userId') || movie['userId'] == null) {
            movie['userId'] = 'guest';
          }
          await db.insert('movies', movie,
              conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (e) {
          print('⚠️ Error restoring movie ${movie['id']}: $e');
        }
      }
      print('✅ Restored ${moviesBackup.length} movies');

      for (var download in downloadsBackup) {
        try {
          // Đảm bảo có userId
          if (!download.containsKey('userId') || download['userId'] == null) {
            download['userId'] = 'guest';
          }
          await db.insert('downloads', download,
              conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (e) {
          print('⚠️ Error restoring download ${download['id']}: $e');
        }
      }
      print('✅ Restored ${downloadsBackup.length} downloads');
    }

    // Version 14: Add trailerKey column
    if (oldVersion < 14) {
      print('🔨 Adding trailerKey column to movies table...');
      try {
        await db.execute('ALTER TABLE movies ADD COLUMN trailerKey TEXT');
        print('✅ Added trailerKey column');
      } catch (e) {
        print('⚠️ Error adding trailerKey column (may already exist): $e');
      }
    }

    // Version 15: Clean duplicate downloads
    if (oldVersion < 15) {
      print('🧹 Cleaning duplicate downloads...');
      try {
        // Xóa duplicate downloads, giữ lại row đầu tiên
        await db.execute('''
          DELETE FROM downloads 
          WHERE rowid NOT IN (
            SELECT MIN(rowid) 
            FROM downloads 
            GROUP BY id, userId
          )
        ''');
        final result =
            await db.rawQuery('SELECT COUNT(*) as count FROM downloads');
        final count = result.first['count'] as int;
        print('✅ Cleaned duplicates. Remaining downloads: $count');
      } catch (e) {
        print('⚠️ Error cleaning duplicates: $e');
      }
    }

    // Ensure notifications table exists
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

  // --- Movie Data (chung cho cả favorites và downloads) ---
  Future<void> saveMovie(Movie movie, String userId) async {
    final db = await instance.database;

    // Kiểm tra xem phim đã tồn tại cho user này chưa
    final existing = await db.query('movies',
        where: 'id = ? AND userId = ?', whereArgs: [movie.id, userId]);

    if (existing.isEmpty) {
      // Nếu chưa có, insert mới
      final movieMap = movie.toMap();
      movieMap['userId'] = userId;
      await db.insert('movies', movieMap);
    } else {
      // Nếu đã có, chỉ update các field cần thiết, GIỮ NGUYÊN isFavorite và isInWatchlist
      final movieMap = movie.toMap();
      movieMap['userId'] = userId;
      // Loại bỏ isFavorite và isInWatchlist để không ghi đè
      movieMap.remove('isFavorite');
      movieMap.remove('isInWatchlist');
      await db.update('movies', movieMap,
          where: 'id = ? AND userId = ?', whereArgs: [movie.id, userId]);
    }
  }

  Future<void> addFavorite(Movie movie, String userId) async {
    final db = await instance.database;

    // Kiểm tra xem phim đã tồn tại cho user này chưa
    final existing = await db.query('movies',
        where: 'id = ? AND userId = ?', whereArgs: [movie.id, userId]);

    if (existing.isEmpty) {
      // Nếu chưa có, insert mới với đầy đủ fields
      final movieMap = movie.toMap();
      movieMap['userId'] = userId;
      movieMap['isFavorite'] = 1;
      movieMap['isInWatchlist'] = 0; // Đảm bảo có field này
      movieMap['dateAdded'] = DateTime.now().toIso8601String();
      await db.insert('movies', movieMap);
    } else {
      // Nếu đã có, update isFavorite
      await db.update('movies',
          {'isFavorite': 1, 'dateAdded': DateTime.now().toIso8601String()},
          where: 'id = ? AND userId = ?', whereArgs: [movie.id, userId]);
    }
  }

  Future<List<Movie>> getFavorites(String userId) async {
    final db = await instance.database;
    final result = await db.query('movies',
        where: 'isFavorite = 1 AND userId = ?', whereArgs: [userId]);
    return result.map((json) => Movie.fromMap(json)).toList();
  }

  Future<void> removeFavorite(int id, String userId) async {
    final db = await instance.database;
    await db.update('movies', {'isFavorite': 0},
        where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<bool> isFavorite(int id, String userId) async {
    final db = await instance.database;
    final result = await db.query('movies',
        where: 'id = ? AND userId = ? AND isFavorite = 1',
        whereArgs: [id, userId]);
    return result.isNotEmpty;
  }

  // --- Watchlist ---
  Future<void> toggleWatchlist(Movie movie, String userId) async {
    final db = await instance.database;

    // Kiểm tra xem phim đã tồn tại cho user này chưa
    final existing = await db.query('movies',
        where: 'id = ? AND userId = ?', whereArgs: [movie.id, userId]);

    if (existing.isEmpty) {
      // Nếu chưa có, insert mới với đầy đủ fields
      final movieMap = movie.toMap();
      movieMap['userId'] = userId;
      movieMap['isFavorite'] = 0; // Đảm bảo có field này
      movieMap['isInWatchlist'] = 1;
      movieMap['dateAdded'] = DateTime.now().toIso8601String();
      await db.insert('movies', movieMap);
    } else {
      // Nếu đã có, toggle isInWatchlist dựa trên giá trị hiện tại
      final currentWatchlistStatus = existing.first['isInWatchlist'] as int;
      final newWatchlistStatus = currentWatchlistStatus == 1 ? 0 : 1;

      await db.update(
        'movies',
        {
          'isInWatchlist': newWatchlistStatus,
          'dateAdded': DateTime.now().toIso8601String()
        },
        where: 'id = ? AND userId = ?',
        whereArgs: [movie.id, userId],
      );
    }
  }

  Future<List<Movie>> getWatchlist(String userId) async {
    final db = await instance.database;
    final result = await db.query('movies',
        where: 'isInWatchlist = 1 AND userId = ?', whereArgs: [userId]);
    return result.map((json) => Movie.fromMap(json)).toList();
  }

  Future<bool> isInWatchlist(int id, String userId) async {
    final db = await instance.database;
    final result = await db.query('movies',
        where: 'id = ? AND userId = ? AND isInWatchlist = 1',
        whereArgs: [id, userId]);
    return result.isNotEmpty;
  }

  Future<void> removeWatchlist(int id, String userId) async {
    final db = await instance.database;
    await db.update('movies', {'isInWatchlist': 0},
        where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  // --- Downloads ---
  Future<void> addDownload(int movieId, String filePath, String userId) async {
    final db = await database;
    await db.insert(
        'downloads', {'id': movieId, 'userId': userId, 'filePath': filePath},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeDownload(int movieId, String userId) async {
    final db = await database;
    await db.delete('downloads',
        where: 'id = ? AND userId = ?', whereArgs: [movieId, userId]);
  }

  // Lấy thông tin các phim đã tải cho user cụ thể
  Future<Map<int, String>> getDownloadedFilePaths(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> result =
        await db.query('downloads', where: 'userId = ?', whereArgs: [userId]);
    return {for (var e in result) e['id'] as int: e['filePath'] as String};
  }

  // Lấy thông tin chi tiết các phim đã tải từ bảng 'movies' cho user cụ thể
  Future<List<Movie>> getDownloadedMovies(
      List<int> movieIds, String userId) async {
    if (movieIds.isEmpty) return [];
    final db = await database;
    final result = await db.query('movies',
        where: 'id IN (${movieIds.join(',')}) AND userId = ?',
        whereArgs: [userId]);
    return result.map((json) => Movie.fromMap(json)).toList();
  }

  // Lấy thông tin chi tiết các phim đã tải và đường dẫn file trong một lần truy vấn cho user cụ thể
  Future<List<Map<String, dynamic>>> getDownloadedMoviesWithPaths(
      String userId) async {
    final db = await database;
    // Sử dụng INNER JOIN để kết hợp bảng 'movies' và 'downloads'
    // Thêm DISTINCT và GROUP BY để loại bỏ duplicate
    final result = await db.rawQuery('''
      SELECT DISTINCT m.*, d.filePath
      FROM movies m
      INNER JOIN downloads d ON m.id = d.id
      WHERE d.userId = ?
      GROUP BY m.id
    ''', [userId]);
    return result;
  }

  /// Fetches a single movie from the DB to check its status,
  /// then returns a new Movie object with the combined data.
  Future<Movie> getMovieWithLocalStatus(
      Movie movieFromApi, String userId) async {
    final db = await instance.database;
    final result = await db.query('movies',
        where: 'id = ? AND userId = ?', whereArgs: [movieFromApi.id, userId]);

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
