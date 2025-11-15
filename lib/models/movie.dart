import 'genre.dart'; // Import Genre from its own file
import 'cast.dart'; // Import Cast from its own file

class Crew {
  final String name;
  final String job;
  Crew({required this.name, required this.job});
  factory Crew.fromJson(Map<String, dynamic> json) =>
      Crew(name: json['name'], job: json['job']);
}

// === Updated Movie model ===
class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final double voteAverage;
  final int voteCount; // Thêm trường này

  // --- NEW DATA ---
  final List<Genre>? genres; // Cho "Action" tag
  final int? runtime; // Cho "2:30 Hour" tag
  final List<Cast>? cast; // Cho "CAST" list
  final List<Crew>? crew; // Cho "Director", "Screenplay"
  final List<Movie>? recommendations; // Cho "RELATED VIDEO"
  final String? trailerKey; // Key của video trailer trên YouTube
  final String mediaType; // 'movie' hoặc 'tv'
  final DateTime? releaseDate; // Thêm trường này
  final DateTime? dateAdded; // Thêm trường ngày thêm vào danh sách

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    required this.voteAverage,
    required this.voteCount,
    // Thêm vào constructor
    this.genres, // Add to constructor
    this.runtime, // Add to constructor
    this.cast, // Add to constructor
    this.crew, // Add to constructor
    this.recommendations, // Add to constructor
    this.trailerKey, // Add to constructor
    this.mediaType = 'movie', // Mặc định là 'movie'
    this.releaseDate, // Thêm vào constructor
    this.dateAdded, // Thêm vào constructor
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Trích xuất dữ liệu mới từ JSON
    final genresList = json['genres'] as List?;
    final credits = json['credits'] as Map<String, dynamic>?;
    final recommendationsList =
        json['recommendations'] as Map<String, dynamic>?;
    final videosList = json['videos']?['results'] as List?;

    // Debug: In ra toàn bộ videos
    final movieId = json['id'];
    final movieTitle = json['title'] ?? json['name'] ?? 'Unknown';
    print('🎬 Parsing movie: $movieTitle (ID: $movieId)');
    if (videosList != null) {
      print('🎥 Found ${videosList.length} videos for movie $movieId');
    }

    // Tìm trailer chính thức từ danh sách video
    String? officialTrailerKey;
    if (videosList != null && videosList.isNotEmpty) {
      try {
        final trailer = videosList.firstWhere(
          (video) =>
              video['type']?.toString().toLowerCase() == 'trailer' &&
              video['site']?.toString().toLowerCase() == 'youtube',
          orElse: () => null,
        );
        if (trailer != null && trailer['key'] != null) {
          // CRITICAL: Đảm bảo key là String và có độ dài hợp lệ (11 ký tự cho YouTube)
          final rawKey = trailer['key'];
          if (rawKey is String) {
            officialTrailerKey = rawKey.trim();
          } else if (rawKey is int) {
            // Nếu là int, convert sang String
            officialTrailerKey = rawKey.toString();
          } else {
            // Fallback: convert bất kỳ kiểu nào sang String
            officialTrailerKey = rawKey.toString();
          }

          // Validate YouTube video ID format (phải là 11 ký tự)
          if (officialTrailerKey.length == 11) {
            print(
                '✅ Movie $movieId ($movieTitle) - Trailer key: $officialTrailerKey');
          } else {
            print(
                '⚠️ Movie $movieId - Invalid trailer key length: ${officialTrailerKey.length} for key: $officialTrailerKey');
            officialTrailerKey = null;
          }
        } else {
          print('⚠️ Movie $movieId - No valid trailer found in videos list');
        }
      } catch (e) {
        print('❌ Movie $movieId - Error parsing trailer: $e');
        officialTrailerKey = null;
      }
    } else {
      print('⚠️ Movie $movieId - No videos available');
    }

    return Movie(
      id: json['id'],
      title: json['title'] ??
          json['name'] ??
          'Untitled', // Xử lý cả 'name' cho TV shows
      overview: json['overview'],
      posterPath: json['poster_path'],
      voteAverage: (json['vote_average'] as num).toDouble(),
      voteCount: json['vote_count'] ?? 0,

      // --- ÁNH XẠ DỮ LIỆU MỚI ---
      genres: genresList?.map((g) => Genre.fromJson(g)).toList(),
      runtime: json['runtime'] as int?,
      mediaType: json['media_type'] ??
          (json.containsKey('first_air_date') ? 'tv' : 'movie'),
      cast: (credits?['cast'] as List?)?.map((c) => Cast.fromJson(c)).toList(),
      crew: (credits?['crew'] as List?)?.map((c) => Crew.fromJson(c)).toList(),
      recommendations: (recommendationsList?['results'] as List?)
          ?.map((m) => Movie.fromJson(m))
          .toList(),
      trailerKey: officialTrailerKey,
      releaseDate:
          DateTime.tryParse(json['release_date'] ?? ''), // Parse release_date
    );
  }

  // Thêm lại các phương thức toMap và fromMap để lưu vào database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'posterPath': posterPath,
      'voteAverage': voteAverage,
      'voteCount': voteCount,
      'isFavorite': 0, // Mặc định khi lưu từ API
      'isInWatchlist': 0, // Mặc định khi lưu từ API
      'mediaType': mediaType,
      'genres': _genresListToString(genres), // Convert list to string
      'runtime': runtime,
      'releaseDate': releaseDate?.toIso8601String(), // Store as ISO string
      'dateAdded': dateAdded?.toIso8601String(),
      'trailerKey': trailerKey, // ✅ Lưu trailerKey vào database
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'],
      title: map['title'],
      overview: map['overview'],
      posterPath: map['posterPath'],
      voteAverage: map['voteAverage'],
      voteCount: map['voteCount'] ?? 0,
      mediaType: map['mediaType'] ?? 'movie',
      // Populate genres and runtime from DB
      genres: (map['genres'] as String?)
          ?.split(',')
          .map((id) => Genre(
              id: int.parse(id),
              name: '')) // Name is not stored, so it's empty for DB retrieval
          .toList(),
      runtime: map['runtime'] as int?,
      releaseDate:
          DateTime.tryParse(map['releaseDate'] ?? ''), // Parse from DB string
      dateAdded: DateTime.tryParse(map['dateAdded'] ?? ''),
      trailerKey: map['trailerKey'] as String?, // ✅ Load trailerKey từ database
    );
  }

  // Helper to convert genres list to a comma-separated string of IDs
  String? _genresListToString(List<Genre>? genres) {
    return genres?.map((g) => g.id.toString()).join(',');
  }

  // copyWith method for creating modified copies
  Movie copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    double? voteAverage,
    int? voteCount,
    List<Genre>? genres,
    int? runtime,
    List<Cast>? cast,
    List<Crew>? crew,
    List<Movie>? recommendations,
    String? trailerKey,
    String? mediaType,
    DateTime? releaseDate,
    DateTime? dateAdded,
    bool? isFavorite,
    bool? isInWatchlist,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      genres: genres ?? this.genres,
      runtime: runtime ?? this.runtime,
      cast: cast ?? this.cast,
      crew: crew ?? this.crew,
      recommendations: recommendations ?? this.recommendations,
      trailerKey: trailerKey ?? this.trailerKey,
      mediaType: mediaType ?? this.mediaType,
      releaseDate: releaseDate ?? this.releaseDate,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
}
