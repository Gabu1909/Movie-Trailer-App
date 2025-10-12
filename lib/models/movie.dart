class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final double voteAverage;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    required this.voteAverage,
  });

  // Factory constructor for API (JSON)
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      overview: json['overview'],
      // 'poster_path' can be null
      posterPath: json['poster_path'],
      // API returns a 'num', cast to double
      voteAverage: (json['vote_average'] as num).toDouble(),
    );
  }

  // Convert Movie object to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'posterPath': posterPath,
      'voteAverage': voteAverage,
    };
  }

  // Create Movie object from a Map (used for database retrieval)
  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'],
      title: map['title'],
      overview: map['overview'],
      posterPath: map['posterPath'],
      // In SQLite, REAL is retrieved as dynamic, ensure correct casting
      voteAverage: (map['voteAverage'] as num).toDouble(),
    );
  }
}
