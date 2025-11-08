import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/genre.dart';
import '../models/actor_detail.dart';
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

  Future<List<Movie>> getUpcomingMovies() async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/upcoming?api_key=${ApiConstants.apiKey}');
  }

  Future<List<Movie>> getMoviesByGenre(String genreId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/discover/movie')
        .replace(queryParameters: {
      'api_key': ApiConstants.apiKey,
      'with_genres': genreId,
    });
    return _getMovies(uri.toString());
  }

  // === DISCOVER WITH FILTERS (Thêm mới) ===
  Future<List<Movie>> discoverMovies(
      String genreIds, String countryCodes) async {
    final queryParams = <String, String>{
      'api_key': ApiConstants.apiKey,
    };

    if (genreIds.isNotEmpty) {
      queryParams['with_genres'] = genreIds;
    }

    if (countryCodes.isNotEmpty) {
      queryParams['with_origin_country'] = countryCodes;
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/discover/movie')
        .replace(queryParameters: queryParams);
    return _getMovies(uri.toString());
  }

  Future<List<Movie>> discoverTVShows(
      String genreIds, String countryCodes) async {
    final queryParams = <String, String>{
      'api_key': ApiConstants.apiKey,
    };

    if (genreIds.isNotEmpty) {
      queryParams['with_genres'] = genreIds;
    }

    if (countryCodes.isNotEmpty) {
      queryParams['with_origin_country'] = countryCodes;
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/discover/tv')
        .replace(queryParameters: queryParams);
    return _getMovies(uri.toString());
  }

  // === TV SHOWS ===
  Future<List<Movie>> getPopularTVShows() async {
    return _getMovies(
        '${ApiConstants.baseUrl}/tv/popular?api_key=${ApiConstants.apiKey}');
  }

  Future<List<Movie>> getTVShowsByGenre(String genreId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/discover/tv')
        .replace(queryParameters: {
      'api_key': ApiConstants.apiKey,
      'with_genres': genreId,
    });
    return _getMovies(uri.toString());
  }

  Future<List<Movie>> searchMovies(String query) async {
    return _getMovies(
        '${ApiConstants.baseUrl}/search/movie?query=$query&api_key=${ApiConstants.apiKey}');
  }

  Future<Movie> getMovieDetail(int movieId) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/movie/$movieId?api_key=${ApiConstants.apiKey}&append_to_response=credits,recommendations,videos'));
    if (response.statusCode == 200) {
      return Movie.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load movie detail');
    }
  }

  Future<Movie> getTvShowDetail(int tvId) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/tv/$tvId?api_key=${ApiConstants.apiKey}&append_to_response=credits,recommendations,videos'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Movie.fromJson(data);
    } else {
      throw Exception('Failed to load TV show detail');
    }
  }

  Future<ActorDetail> getActorDetails(int actorId) async {
    final dio = Dio();
    try {
      final response = await dio.get(
        '${ApiConstants.baseUrl}/person/$actorId',
        queryParameters: {
          'api_key': ApiConstants.apiKey,
          'append_to_response': 'movie_credits,tv_credits'
        },
      );
      return ActorDetail.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load actor details: $e');
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
