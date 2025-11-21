import 'movie.dart';
import 'review.dart';

class UserReviewWithMovie {
  final Review review;
  final Movie movie;

  UserReviewWithMovie({
    required this.review,
    required this.movie,
  });

  // Factory constructor để tạo từ map (kết quả của câu lệnh JOIN trong DB)
  factory UserReviewWithMovie.fromMap(Map<String, dynamic> map) {
    // Tạo đối tượng Review và Movie từ map
    final review = Review.fromMap(map);
    final movie = Movie.fromMap(map);
    return UserReviewWithMovie(review: review, movie: movie);
  }
}