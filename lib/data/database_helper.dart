import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/movie.dart';

class DatabaseHelper {
  // Singleton Pattern
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Getter cho Database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('favorites.db');
    return _database!;
  }

  // Khởi tạo Database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // Mở database, tạo nếu chưa có
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Tạo bảng khi database được tạo lần đầu
  Future _createDB(Database db, int version) async {
    // Sử dụng cột 'posterPath TEXT' cho phép NULL vì một số phim không có poster
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        overview TEXT NOT NULL,
        posterPath TEXT, 
        voteAverage REAL NOT NULL
      )
    ''');
  }

  // Thêm phim vào danh sách yêu thích
  Future<void> addFavorite(Movie movie) async {
    final db = await instance.database;
    await db.insert('favorites', movie.toMap(),
        // Nếu đã có, thay thế (để tránh trùng lặp)
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Lấy tất cả phim yêu thích
  Future<List<Movie>> getFavorites() async {
    final db = await instance.database;
    final result = await db.query('favorites');
    // Chuyển đổi List<Map> thành List<Movie>
    return result.map((json) => Movie.fromMap(json)).toList();
  }

  // Xóa phim khỏi danh sách yêu thích
  Future<void> removeFavorite(int id) async {
    final db = await instance.database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }
}
