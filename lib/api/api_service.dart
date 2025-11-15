import 'dart:convert';
import 'dart:async' show TimeoutException;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/genre.dart';
import '../models/actor_detail.dart';
import '../models/movie.dart';
import '../models/cast.dart';
import '../utils/exceptions.dart' as app_exceptions;
import '../utils/app_constants.dart';
import 'api_constants.dart';

class ApiService {
  Future<List<Movie>> getNowPlayingMovies() async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/now_playing?api_key=${ApiConstants.apiKey}');
  }

  Future<List<Movie>> getTrendingMoviesOfWeek() async {
    return _getMovies(
        '${ApiConstants.baseUrl}/trending/movie/week?api_key=${ApiConstants.apiKey}');
  }

  Future<List<Movie>> getPopularMovies() async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/popular?api_key=${ApiConstants.apiKey}');
  }

  Future<List<Movie>> getTopRatedMovies() async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/top_rated?api_key=${ApiConstants.apiKey}');
  }

  Future<List<Movie>> getUpcomingMovies({int page = 1}) async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/upcoming?api_key=${ApiConstants.apiKey}&page=$page');
  }

  Future<List<Movie>> getMoviesByGenre(String genreId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/discover/movie')
        .replace(queryParameters: {
      'api_key': ApiConstants.apiKey,
      'with_genres': genreId,
    });
    return _getMovies(uri.toString());
  }

  Future<List<Movie>> discoverMovies(
      String genreIds, String countryCodes) async {
    try {
      final queryParams = <String, String>{
        'api_key': ApiConstants.apiKey,
        'sort_by': 'popularity.desc',
        'page': '1',
      };

      if (genreIds.isNotEmpty) {
        queryParams['with_genres'] = genreIds;
      }

      if (countryCodes.isNotEmpty) {
        queryParams['with_origin_country'] = countryCodes;
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/discover/movie')
          .replace(queryParameters: queryParams);

      print('🌐 API Request: $uri');

      final response = await http.get(uri);

      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        final results = decodedBody['results'] as List;

        print('📊 Results: ${results.length} movies found');

        if (results.isEmpty) {
          print('⚠️ No movies found for these filters');
        }

        return results.map((movie) => Movie.fromJson(movie)).toList();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Exception: $e');
      throw Exception('Failed to load movies: $e');
    }
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

  Future<List<Cast>> searchActors(String query) async {
    try {
      final response = await http.get(Uri.parse(
          '${ApiConstants.baseUrl}/search/person?query=$query&api_key=${ApiConstants.apiKey}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Cast.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search actors');
      }
    } catch (e) {
      debugPrint('Error searching actors: $e');
      return [];
    }
  }

  Future<List<Cast>> getPopularActors() async {
    try {
      final response = await http.get(Uri.parse(
          '${ApiConstants.baseUrl}/person/popular?api_key=${ApiConstants.apiKey}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Cast.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching popular actors: $e');
    }
    return [];
  }

  Future<Movie> getMovieDetail(int movieId) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/movie/$movieId?api_key=${ApiConstants.apiKey}&append_to_response=credits,recommendations,videos'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['videos'] != null) {
        print('🎥 Raw videos data: ${jsonData['videos']}');
      }
      return Movie.fromJson(jsonData);
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
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        try {
          final decodedBody = json.decode(response.body)['results'] as List;
          return decodedBody.map((movie) => Movie.fromJson(movie)).toList();
        } on FormatException catch (e) {
          debugPrint('JSON Parse Error: $e');
          throw app_exceptions.ParseException(
            'Invalid response format',
            originalError: e,
          );
        }
      } else {
        debugPrint('API Error ${response.statusCode}: ${response.body}');
        throw app_exceptions.ApiException(
          'Failed to load movies',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      debugPrint('API Timeout: $url');
      throw app_exceptions.TimeoutException('Request timed out');
    } on SocketException {
      debugPrint('Network Error: No internet connection');
      throw app_exceptions.NetworkException('No internet connection');
    } catch (e) {
      debugPrint('Unexpected Error: $e');
      if (e is app_exceptions.ApiException ||
          e is app_exceptions.TimeoutException ||
          e is app_exceptions.NetworkException ||
          e is app_exceptions.ParseException) {
        rethrow;
      }
      throw app_exceptions.ApiException(
        'Failed to load movies',
        originalError: e,
      );
    }
  }
}
