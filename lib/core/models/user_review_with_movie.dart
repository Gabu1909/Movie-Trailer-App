import 'movie.dart';
import 'review.dart';

class UserReviewWithMovie {
  final Review review;
  final Movie movie;

  UserReviewWithMovie({
    required this.review,
    required this.movie,
  });

  factory UserReviewWithMovie.fromMap(Map<String, dynamic> map) {
    final review = Review.fromMap(map);
    final movie = Movie.fromMap(map);
    return UserReviewWithMovie(review: review, movie: movie);
  }
}