import 'genre.dart'; // Import Genre from its own file

class Cast {
  final int id;
  final String name;
  final String? profilePath;
  Cast({required this.id, required this.name, this.profilePath});
  factory Cast.fromJson(Map<String, dynamic> json) => Cast(
      id: json['id'], name: json['name'], profilePath: json['profile_path']);
}

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

  // --- NEW DATA ---
  final List<Genre>? genres; // Cho "Action" tag
  final int? runtime; // Cho "2:30 Hour" tag
  final List<Cast>? cast; // Cho "CAST" list
  final List<Crew>? crew; // Cho "Director", "Screenplay"
  final List<Movie>? recommendations; // Cho "RELATED VIDEO"
  final String? trailerKey; // Key của video trailer trên YouTube
  final String mediaType; // 'movie' hoặc 'tv'

  // --- LOCAL DB DATA ---
  final bool isFavorite;
  final bool isInWatchlist;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    required this.voteAverage,
    // Thêm vào constructor
    this.genres, // Add to constructor
    this.runtime, // Add to constructor
    this.cast, // Add to constructor
    this.crew, // Add to constructor
    this.recommendations, // Add to constructor
    this.trailerKey, // Add to constructor
    this.mediaType = 'movie', // Mặc định là 'movie'
    this.isFavorite = false, // Default to false
    this.isInWatchlist = false, // Default to false
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Trích xuất dữ liệu mới từ JSON
    final genresList = json['genres'] as List?;
    final credits = json['credits'] as Map<String, dynamic>?;
    final recommendationsList =
        json['recommendations'] as Map<String, dynamic>?;
    final videosList = json['videos']?['results'] as List?;

    // Tìm trailer chính thức từ danh sách video
    String? officialTrailerKey;
    if (videosList != null) {
      final officialTrailer = videosList.firstWhere(
        (video) => video['type'] == 'Trailer' && video['official'] == true,
        orElse: () => videosList.firstWhere(
            (video) => video['type'] == 'Trailer',
            orElse: () => null),
      );
      officialTrailerKey = officialTrailer?['key'];
    }

    return Movie(
      id: json['id'],
      title: json['title'] ??
          json['name'] ??
          'Untitled', // Xử lý cả 'name' cho TV shows
      overview: json['overview'],
      posterPath: json['poster_path'],
      voteAverage: (json['vote_average'] as num).toDouble(),

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
      'isFavorite': isFavorite ? 1 : 0,
      'isInWatchlist': isInWatchlist ? 1 : 0,
      'mediaType': mediaType,
      'genres': _genresListToString(genres), // Convert list to string
      'runtime': runtime,
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'],
      title: map['title'],
      overview: map['overview'],
      posterPath: map['posterPath'],
      voteAverage: map['voteAverage'],
      mediaType: map['mediaType'] ?? 'movie',
      isFavorite: map['isFavorite'] == 1,
      isInWatchlist: map['isInWatchlist'] == 1,
      // Populate genres and runtime from DB
      genres: (map['genres'] as String?)
          ?.split(',')
          .map((id) => Genre(
              id: int.parse(id),
              name: '')) // Name is not stored, so it's empty for DB retrieval
          .toList(),
      runtime: map['runtime'] as int?,
    );
  }

  // Helper to convert genres list to a comma-separated string of IDs
  String? _genresListToString(List<Genre>? genres) {
    return genres?.map((g) => g.id.toString()).join(',');
  }

  // The missing copyWith method
  Movie copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    double? voteAverage,
    List<Genre>? genres,
    int? runtime,
    List<Cast>? cast,
    List<Crew>? crew,
    List<Movie>? recommendations,
    String? trailerKey,
    String? mediaType,
    bool? isFavorite,
    bool? isInWatchlist,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      voteAverage: voteAverage ?? this.voteAverage,
      genres: genres ?? this.genres,
      runtime: runtime ?? this.runtime,
      cast: cast ?? this.cast,
      crew: crew ?? this.crew,
      recommendations: recommendations ?? this.recommendations,
      trailerKey: trailerKey ?? this.trailerKey,
      mediaType: mediaType ?? this.mediaType,
      isFavorite: isFavorite ?? this.isFavorite,
      isInWatchlist: isInWatchlist ?? this.isInWatchlist,
    );
  }
}
