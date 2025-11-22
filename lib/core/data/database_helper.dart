import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/models/movie.dart';
import '../../core/models/review.dart';
import '../../core/models/user_review_with_movie.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _hasCheckedNotificationsTable = false;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      if (!_hasCheckedNotificationsTable) {
        await _ensureNotificationsTableHasUserId(_database!);
        _hasCheckedNotificationsTable = true;
      }
      return _database!;
    }
    _database = await _initDB('favorites.db');
    await _ensureNotificationsTableHasUserId(_database!);
    _hasCheckedNotificationsTable = true;
    return _database!;
  }

  /// Đảm bảo bảng notifications có cột userId
  /// - Chạy 1 lần duy nhất khi app khởi động (nhờ flag _hasCheckedNotificationsTable)
  /// - Dùng để fix database của những app đã cài đặt trước khi thêm feature notifications
  /// - Không ảnh hưởng đến app mới cài đặt (table đã có userId từ _createDB)
  Future<void> _ensureNotificationsTableHasUserId(Database db) async {
    try {
      // Kiểm tra bảng notifications có tồn tại không
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='notifications'");

      if (tables.isNotEmpty) {
        // Kiểm tra cột userId đã tồn tại chưa
        final tableInfo = await db.rawQuery('PRAGMA table_info(notifications)');
        final hasUserId = tableInfo.any((column) => column['name'] == 'userId');

        if (!hasUserId) {
          print('FIXING: Adding userId column to notifications table...');
          // Thêm cột userId với giá trị mặc định "guest" cho data cũ
          await db.execute(
              'ALTER TABLE notifications ADD COLUMN userId TEXT NOT NULL DEFAULT "guest"');
          // Tạo index để query nhanh theo userId
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_notifications_userId ON notifications(userId)');
          print('FIXED: userId column added to notifications table!');
        }
      }
    } catch (e) {
      print('Error ensuring userId column: $e');
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path,
        version: 23, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS movies (
        id INTEGER NOT NULL,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        overview TEXT NOT NULL,
        posterPath TEXT,
        backdropPath TEXT,
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
      CREATE TABLE IF NOT EXISTS downloads (
        id INTEGER NOT NULL,
        userId TEXT NOT NULL,
        filePath TEXT NOT NULL,
        PRIMARY KEY (id, userId)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        imageUrl TEXT,
        route TEXT,
        routeArgs TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_reviews (
        movieId INTEGER NOT NULL,
        userId TEXT NOT NULL,
        rating REAL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        authorName TEXT,
        authorAvatarPath TEXT,
        PRIMARY KEY (movieId, userId)
      )
    ''');
    print('Created user_reviews table');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS review_replies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movieId INTEGER NOT NULL,
        parentReviewAuthor TEXT NOT NULL,
        replyContent TEXT NOT NULL,
        replyAuthor TEXT NOT NULL,
        replyAuthorAvatar TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (movieId) REFERENCES user_reviews (movieId) ON DELETE CASCADE
      )
    ''');
    print('Created review_replies table');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_movies_userId ON movies(userId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_movies_dateAdded ON movies(dateAdded)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_downloads_userId ON downloads(userId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_timestamp ON notifications(timestamp)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_user_reviews_userId ON user_reviews(userId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_review_replies_movieId ON review_replies(movieId, parentReviewAuthor)');
    print('Database indexes created');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Database upgrade from version $oldVersion to $newVersion');

    if (oldVersion < 22) {
      print('Version 22: Rebuilding database with complete schema...');

      List<Map<String, dynamic>> moviesBackup = [];
      try {
        moviesBackup = await db.query('movies');
        print('Backed up ${moviesBackup.length} movies');
      } catch (e) {
        print('No existing movies table: $e');
      }

      List<Map<String, dynamic>> downloadsBackup = [];
      try {
        downloadsBackup = await db.query('downloads');
        print('Backed up ${downloadsBackup.length} downloads');
      } catch (e) {
        print('No existing downloads table: $e');
      }

      await db.execute('DROP TABLE IF EXISTS movies');
      await db.execute('''
        CREATE TABLE movies (
          id INTEGER NOT NULL,
          userId TEXT NOT NULL,
          title TEXT NOT NULL,
          overview TEXT NOT NULL,
          posterPath TEXT,
          backdropPath TEXT,
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
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_movies_userId ON movies(userId)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_movies_dateAdded ON movies(dateAdded)');
      print('Created movies table with indexes');

      await db.execute('DROP TABLE IF EXISTS downloads');
      await db.execute('''
        CREATE TABLE downloads (
          id INTEGER NOT NULL,
          userId TEXT NOT NULL,
          filePath TEXT NOT NULL,
          PRIMARY KEY (id, userId)
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_downloads_userId ON downloads(userId)');
      print('Created downloads table with index');

      await db.execute('DROP TABLE IF EXISTS user_reviews');
      await db.execute('''
        CREATE TABLE user_reviews (
          movieId INTEGER NOT NULL,
          userId TEXT NOT NULL,
          rating REAL,
          content TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          authorName TEXT,
          authorAvatarPath TEXT,
          PRIMARY KEY (movieId, userId)
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_user_reviews_userId ON user_reviews(userId)');
      print('Created user_reviews table with index');

      await db.execute('DROP TABLE IF EXISTS review_replies');
      await db.execute('''
        CREATE TABLE review_replies (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          movieId INTEGER NOT NULL,
          parentReviewAuthor TEXT NOT NULL,
          replyContent TEXT NOT NULL,
          replyAuthor TEXT NOT NULL,
          replyAuthorAvatar TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_review_replies_movieId ON review_replies(movieId, parentReviewAuthor)');
      print('Created review_replies table with index');

      for (var movie in moviesBackup) {
        try {
          if (!movie.containsKey('userId') || movie['userId'] == null) {
            movie['userId'] = 'guest';
          }
          await db.insert('movies', movie,
              conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (e) {
          print('Error restoring movie ${movie['id']}: $e');
        }
      }
      print('Restored ${moviesBackup.length} movies');

      for (var download in downloadsBackup) {
        try {
          if (!download.containsKey('userId') || download['userId'] == null) {
            download['userId'] = 'guest';
          }
          await db.insert('downloads', download,
              conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (e) {
          print('Error restoring download ${download['id']}: $e');
        }
      }
      print('Restored ${downloadsBackup.length} downloads');

      print(
          'Version 22 migration complete! Reviews were reset (users need to re-submit)');
    }

    // Version 23: Notifications table với userId
    // NOTE: Không cần tạo table ở đây vì:
    // - App mới: table được tạo tự động trong _createDB (dòng 63)
    // - App cũ: table được fix tự động bởi _ensureNotificationsTableHasUserId (dòng 29)
    if (oldVersion < 23) {
      print('Version 23: Notifications table will be handled automatically');
    }
  }

  Future<void> saveMovie(Movie movie, String userId) async {
    final db = await instance.database;

    final existing = await db.query('movies',
        where: 'id = ? AND userId = ?', whereArgs: [movie.id, userId]);

    if (existing.isEmpty) {
      final movieMap = movie.toMap();
      movieMap['userId'] = userId;
      await db.insert('movies', movieMap);
    } else {
      final movieMap = movie.toMap();
      movieMap['userId'] = userId;
      movieMap.remove('isFavorite');
      movieMap.remove('isInWatchlist');
      await db.update('movies', movieMap,
          where: 'id = ? AND userId = ?', whereArgs: [movie.id, userId]);
    }
  }

  Future<void> addFavorite(Movie movie, String userId) async {
    final db = await instance.database;

    final existing = await db.query('movies',
        where: 'id = ? AND userId = ?', whereArgs: [movie.id, userId]);

    if (existing.isEmpty) {
      final movieMap = movie.toMap();
      movieMap['userId'] = userId;
      movieMap['isFavorite'] = 1;
      movieMap['isInWatchlist'] = 0;
      movieMap['dateAdded'] = DateTime.now().toIso8601String();
      await db.insert('movies', movieMap);
    } else {
      await db.update('movies',
          {'isFavorite': 1, 'dateAdded': DateTime.now().toIso8601String()},
          where: 'id = ? AND userId = ?', whereArgs: [movie.id, userId]);
    }
  }

  Future<List<Movie>> getFavorites(String userId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'movies',
      where: 'isFavorite = 1 AND userId = ?',
      whereArgs: [userId],
      orderBy: 'dateAdded DESC',
    );
    return compute(_parseMovieList, result);
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

  Future<void> toggleWatchlist(Movie movie, String userId) async {
    final db = await instance.database;

    final existing = await db.query('movies',
        where: 'id = ? AND userId = ?', whereArgs: [movie.id, userId]);

    if (existing.isEmpty) {
      final movieMap = movie.toMap();
      movieMap['userId'] = userId;
      movieMap['isFavorite'] = 0;
      movieMap['isInWatchlist'] = 1;
      movieMap['dateAdded'] = DateTime.now().toIso8601String();
      await db.insert('movies', movieMap);
    } else {
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
    final result = await db.query(
      'movies',
      where: 'isInWatchlist = 1 AND userId = ?',
      whereArgs: [userId],
      orderBy: 'dateAdded DESC',
    );
    return compute(_parseMovieList, result);
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

  Future<Map<int, String>> getDownloadedFilePaths(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> result =
        await db.query('downloads', where: 'userId = ?', whereArgs: [userId]);
    return {for (var e in result) e['id'] as int: e['filePath'] as String};
  }

  Future<List<Movie>> getDownloadedMovies(
      List<int> movieIds, String userId) async {
    if (movieIds.isEmpty) return [];
    final db = await database;
    final result = await db.query('movies',
        where: 'id IN (${movieIds.join(',')}) AND userId = ?',
        whereArgs: [userId]);
    return result.map((json) => Movie.fromMap(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getDownloadedMoviesWithPaths(
      String userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT m.*, d.filePath
      FROM movies m
      INNER JOIN downloads d ON m.id = d.id
      WHERE d.userId = ?
      GROUP BY m.id
    ''', [userId]);
    return result;
  }

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
    return movieFromApi;
  }

  Future<void> saveUserReview(int movieId, String userId, double rating,
      String content, String? authorName, String? authorAvatarPath) async {
    final db = await instance.database;
    await db.insert(
      'user_reviews',
      {
        'movieId': movieId,
        'userId': userId,
        'rating': rating,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
        'authorName': authorName,
        'authorAvatarPath': authorAvatarPath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Saved review for movie $movieId by user $userId');
  }

  Future<Review?> getUserReview(int movieId, String userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'user_reviews',
      where: 'movieId = ? AND userId = ?',
      whereArgs: [movieId, userId],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      final authorName =
          map.containsKey('authorName') ? map['authorName'] as String? : null;
      final avatarPath = map.containsKey('authorAvatarPath')
          ? map['authorAvatarPath'] as String?
          : null;

      return Review(
        author: authorName ?? 'You',
        content: map['content'] as String,
        createdAt: map['createdAt'] as String,
        rating: map['rating'] as double?,
        avatarPath: avatarPath,
      );
    }
    return null;
  }

  Future<void> deleteUserReview(int movieId, String userId) async {
    final db = await instance.database;
    final existing = await db.query('user_reviews',
        where: 'movieId = ? AND userId = ?', whereArgs: [movieId, userId]);
    print(
        'Found ${existing.length} review(s) to delete for movieId: $movieId, userId: $userId');
    if (existing.isNotEmpty) {
      print('Review data: ${existing.first}');
    }

    final deletedCount = await db.delete('user_reviews',
        where: 'movieId = ? AND userId = ?', whereArgs: [movieId, userId]);
    print(
        'Deleted $deletedCount review(s) for movie ID: $movieId by user $userId');
  }

  Future<String?> getUserIdByReviewAuthor(
      int movieId, String authorName) async {
    final db = await instance.database;
    final maps = await db.query(
      'user_reviews',
      columns: ['userId'],
      where: 'movieId = ? AND authorName = ?',
      whereArgs: [movieId, authorName],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['userId'] as String?;
    }
    return null;
  }

  Future<List<UserReviewWithMovie>> getAllUserReviews(String userId,
      {int limit = 20, int offset = 0}) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        ur.movieId, ur.rating, ur.content, ur.createdAt,
        m.*
      FROM user_reviews ur
      LEFT JOIN movies m ON ur.movieId = m.id AND m.userId = ?
      WHERE ur.userId = ?
      ORDER BY ur.createdAt DESC
      LIMIT ? OFFSET ?
    ''', [userId, userId, limit, offset]);

    if (maps.isEmpty) {
      return [];
    }

    final validReviews = <UserReviewWithMovie>[];
    for (final map in maps) {
      try {
        if (map['id'] != null && map['title'] != null) {
          validReviews.add(UserReviewWithMovie.fromMap(map));
        } else {
          print(
              'Skipping review for movieId ${map['movieId']} - movie data not found');
        }
      } catch (e) {
        print('Error parsing review: $e');
        print('   Map data: $map');
      }
    }

    return validReviews;
  }

  Future<void> saveReviewReply({
    required int movieId,
    required String parentReviewAuthor,
    required String replyContent,
    required String replyAuthor,
    String? replyAuthorAvatar,
  }) async {
    final db = await instance.database;
    await db.insert(
      'review_replies',
      {
        'movieId': movieId,
        'parentReviewAuthor': parentReviewAuthor,
        'replyContent': replyContent,
        'replyAuthor': replyAuthor,
        'replyAuthorAvatar': replyAuthorAvatar,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
    print('Saved reply to review by $parentReviewAuthor for movie $movieId');
  }

  Future<List<Review>> getReviewReplies(
      int movieId, String parentReviewAuthor) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'review_replies',
      where: 'movieId = ? AND parentReviewAuthor = ?',
      whereArgs: [movieId, parentReviewAuthor],
      orderBy: 'createdAt ASC',
    );

    return maps
        .map((map) => Review(
              author: map['replyAuthor'] as String,
              content: map['replyContent'] as String,
              createdAt: map['createdAt'] as String,
              avatarPath: map['replyAuthorAvatar'] as String?,
              replyId: map['id'] as int?,
            ))
        .toList();
  }

  Future<void> deleteReply(int replyId) async {
    final db = await instance.database;
    await db.delete(
      'review_replies',
      where: 'id = ?',
      whereArgs: [replyId],
    );
    print('Deleted reply with id $replyId');
  }

  Future<void> deleteReviewReplies(
      int movieId, String parentReviewAuthor) async {
    final db = await instance.database;
    await db.delete(
      'review_replies',
      where: 'movieId = ? AND parentReviewAuthor = ?',
      whereArgs: [movieId, parentReviewAuthor],
    );
    print('Deleted all replies for review by $parentReviewAuthor');
  }

  Future<void> saveNotification(Map<String, dynamic> notification) async {
    final db = await instance.database;
    print('DatabaseHelper.saveNotification:');
    print('ID: ${notification['id']}');
    print('UserId: ${notification['userId']}');
    print('Title: ${notification['title']}');

    await db.insert(
      'notifications',
      notification,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Notification saved to database');
  }

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final db = await instance.database;
    print('DatabaseHelper.getNotifications for userId: $userId');

    final results = await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );

    print('Found ${results.length} notifications in database');
    return results;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final db = await instance.database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<void> clearNotifications(String userId) async {
    final db = await instance.database;
    await db.delete(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }
}

List<Movie> _parseMovieList(List<Map<String, dynamic>> maps) {
  return maps.map((json) => Movie.fromMap(json)).toList();
}
