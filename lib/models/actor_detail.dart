import 'movie.dart';

class ActorDetail {
  final int id;
  final String name;
  final String? profilePath;
  final String? biography;
  final String? birthday;
  final String? placeOfBirth;
  final List<Movie> movieCredits; // Phim đã đóng
  final List<Movie> tvCredits; // TV show đã tham gia

  ActorDetail({
    required this.id,
    required this.name,
    this.profilePath,
    this.biography,
    this.birthday,
    this.placeOfBirth,
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
      movieCredits:
          movieCreditsList?.map((m) => Movie.fromJson(m)).toList() ?? [],
      tvCredits: tvCreditsList?.map((m) => Movie.fromJson(m)).toList() ?? [],
    );
  }
}
