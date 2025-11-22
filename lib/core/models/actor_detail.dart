import 'movie.dart';

class ActorDetail {
  final int id;
  final String name;
  final String? profilePath;
  final String? biography;
  final String? birthday;
  final String? placeOfBirth;
  final int gender; 
  final double popularity;
  final List<Movie> movieCredits; 
  final List<Movie> tvCredits; 

  ActorDetail({
    required this.id,
    required this.name,
    this.profilePath,
    this.biography,
    this.birthday,
    this.placeOfBirth,
    required this.gender,
    required this.popularity,
    required this.movieCredits,
    required this.tvCredits,
  });

  factory ActorDetail.fromJson(Map<String, dynamic> json) {
    final movieCreditsList = json['movie_credits']?['cast'] as List?;
    final tvCreditsList = json['tv_credits']?['cast'] as List?;

    return ActorDetail(
      id: json['id'],
      name: json['name'],
      profilePath: json['profile_path'],
      biography: json['biography'],
      birthday: json['birthday'],
      placeOfBirth: json['place_of_birth'],
      gender: json['gender'] ?? 0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      movieCredits:
          movieCreditsList?.map((m) => Movie.fromJson(m)).toList() ?? [],
      tvCredits: tvCreditsList?.map((m) => Movie.fromJson(m)).toList() ?? [],
    );
  }
}
