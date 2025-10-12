import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/genre.dart';
import '../models/movie.dart';
import 'api_constants.dart';

class ApiService {
  Future<List<Movie>> getNowPlayingMovies() async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/now_playing?api_key=${ApiConstants.apiKey}');
  }

  Future<List<Movie>> getPopularMovies() async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/popular?api_key=${ApiConstants.apiKey}');
  }

  Future<List<Movie>> getTopRatedMovies() async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/top_rated?api_key=${ApiConstants.apiKey}');
  }

  Future<List<Movie>> searchMovies(String query) async {
    return _getMovies(
        '${ApiConstants.baseUrl}/search/movie?query=$query&api_key=${ApiConstants.apiKey}');
  }

  Future<Movie> getMovieDetail(int movieId) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/movie/$movieId?api_key=${ApiConstants.apiKey}'));
    if (response.statusCode == 200) {
      return Movie.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load movie detail');
    }
  }

  Future<List<Genre>> getGenres() async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/genre/movie/list?api_key=${ApiConstants.apiKey}'));
    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body)['genres'] as List;
      return decodedBody.map((genre) => Genre.fromJson(genre)).toList();
    } else {
      throw Exception('Failed to load genres');
    }
  }

  Future<List<Movie>> _getMovies(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body)['results'] as List;
      return decodedBody.map((movie) => Movie.fromJson(movie)).toList();
    } else {
      throw Exception('Failed to load movies');
    }
  }
}
