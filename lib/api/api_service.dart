import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import 'api_constants.dart';

class ApiService {
  // Phương thức chung để gọi API và parse danh sách phim
  Future<List<Movie>> _getMovies(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // Lấy danh sách phim từ khóa 'results'
      final decodedBody = json.decode(response.body)['results'] as List;
      return decodedBody.map((movie) => Movie.fromJson(movie)).toList();
    } else {
      throw Exception('Failed to load movies from: $url');
    }
  }

  // 1. Lấy phim đang chiếu
  Future<List<Movie>> getNowPlayingMovies() async {
    return _getMovies(
      '${ApiConstants.baseUrl}/movie/now_playing?api_key=${ApiConstants.apiKey}',
    );
  }

  // 2. Lấy phim phổ biến
  Future<List<Movie>> getPopularMovies() async {
    return _getMovies(
      '${ApiConstants.baseUrl}/movie/popular?api_key=${ApiConstants.apiKey}',
    );
  }

  // 3. Lấy phim được đánh giá cao nhất
  Future<List<Movie>> getTopRatedMovies() async {
    return _getMovies(
      '${ApiConstants.baseUrl}/movie/top_rated?api_key=${ApiConstants.apiKey}',
    );
  }

  // 4. Tìm kiếm phim
  Future<List<Movie>> searchMovies(String query) async {
    // encode query để đảm bảo các ký tự đặc biệt được xử lý đúng
    final encodedQuery = Uri.encodeComponent(query);
    return _getMovies(
      '${ApiConstants.baseUrl}/search/movie?query=$encodedQuery&api_key=${ApiConstants.apiKey}',
    );
  }

  // 5. Lấy chi tiết phim (Trả về Movie object, không phải List)
  Future<Movie> getMovieDetail(int movieId) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/movie/$movieId?api_key=${ApiConstants.apiKey}',
      ),
    );
    if (response.statusCode == 200) {
      return Movie.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load movie detail for ID: $movieId');
    }
  }
}
