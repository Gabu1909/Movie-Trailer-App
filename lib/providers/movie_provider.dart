import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/genre.dart';
import '../models/movie.dart';

class MovieProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Movie> _popularMovies = [];
  List<Movie> _trendingMovies = [];
  List<Movie> _upcomingMovies = [];
  List<Movie> _kidsMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _searchedMovies = [];
  List<Genre> _genres = [];

  final Map<int, List<Movie>> _cachedGenreMovies = {};

  Set<int> _selectedDrawerGenreIds = {};
  Set<String> _selectedCountries = {};

  bool _isLoading = true;
  bool _isTrendingLoading = false;
  int _selectedGenreIndex = 0;

  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get upcomingMovies => _upcomingMovies;
  List<Movie> get kidsMovies => _kidsMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get searchedMovies => _searchedMovies;
  List<Genre> get genres => _genres;
  bool get isLoading => _isLoading;
  bool get isTrendingLoading => _isTrendingLoading;
  int get selectedGenreIndex => _selectedGenreIndex;
  Set<int> get selectedDrawerGenreIds => _selectedDrawerGenreIds;
  Set<String> get selectedCountries => _selectedCountries;

  bool isGenreSelected(int genreId) =>
      _selectedDrawerGenreIds.contains(genreId);

  bool isCountrySelected(String country) =>
      _selectedCountries.contains(country);

  MovieProvider() {
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    _isLoading = true;
    notifyListeners();

    _cachedGenreMovies.clear();
    _selectedDrawerGenreIds.clear();
    _selectedCountries.clear();

    try {
      await Future.wait([
        _apiService.getPopularMovies(),
        _apiService.getUpcomingMovies(),
        _apiService.getMoviesByGenre('10751'),
        _apiService.getGenres(),
        _apiService.getTopRatedMovies(),
      ]).then((results) {
        _popularMovies = results[0] as List<Movie>;
        _trendingMovies = _popularMovies;
        _upcomingMovies = results[1] as List<Movie>;
        _kidsMovies = results[2] as List<Movie>;
        _genres = results[3] as List<Genre>;
        _topRatedMovies = results[4] as List<Movie>;
        _cachedGenreMovies[0] = _popularMovies;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchMovies(String query) async {
    _isLoading = true;
    _searchedMovies = [];
    notifyListeners();
    if (query.isNotEmpty) {
      try {
        _searchedMovies = await _apiService.searchMovies(query);
      } catch (e) {
        debugPrint('Error searching movies: $e');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTrendingMoviesByGenre(int? genreId) async {
    _isTrendingLoading = true;
    notifyListeners();

    try {
      final id = genreId ?? 0;

      if (_cachedGenreMovies.containsKey(id)) {
        _trendingMovies = _cachedGenreMovies[id]!;
      } else {
        final movies = await _apiService.getMoviesByGenre(id.toString());
        _trendingMovies = movies;
        _cachedGenreMovies[id] = movies;
      }
    } catch (e) {
      debugPrint('Error fetching trending movies by genre: $e');
    }
    _isTrendingLoading = false;
    notifyListeners();
  }

  Future<void> selectGenre(int index, int? genreId) async {
    _selectedGenreIndex = index;
    await fetchTrendingMoviesByGenre(genreId);
  }

  Future<List<Movie>> getPopularTVShows() async {
    try {
      return await _apiService.getPopularTVShows();
    } catch (e) {
      debugPrint('Error fetching TV shows: $e');
      return [];
    }
  }

  void toggleDrawerGenre(int genreId) {
    if (_selectedDrawerGenreIds.contains(genreId)) {
      _selectedDrawerGenreIds.remove(genreId);
    } else {
      _selectedDrawerGenreIds.add(genreId);
    }
    notifyListeners();
  }

  void toggleCountry(String country) {
    if (_selectedCountries.contains(country)) {
      _selectedCountries.remove(country);
    } else {
      _selectedCountries.add(country);
    }
    notifyListeners();
  }

  // Map country names to ISO 3166-1 codes
  String _getCountryCode(String country) {
    const countryMap = {
      'USA': 'US',
      'India': 'IN',
      'Korea': 'KR',
      'Japan': 'JP',
      'China': 'CN',
      'Vietnam': 'VN',
    };
    return countryMap[country] ?? country;
  }

  Future<List<Movie>> getMoviesForSelectedGenres() async {
    if (_selectedDrawerGenreIds.isEmpty && _selectedCountries.isEmpty) {
      return popularMovies;
    }

    // Build API call with filters
    if (_selectedDrawerGenreIds.isNotEmpty || _selectedCountries.isNotEmpty) {
      try {
        final genreIds = _selectedDrawerGenreIds.join(',');
        final countryCodes =
            _selectedCountries.map((c) => _getCountryCode(c)).join('|');

        final movies = await _apiService.discoverMovies(genreIds, countryCodes);

        return movies;
      } catch (e) {
        debugPrint('Error fetching filtered movies: $e');
        return [];
      }
    }

    return popularMovies;
  }

  void clearDrawerGenres() {
    _selectedDrawerGenreIds.clear();
    _selectedCountries.clear();
    notifyListeners();
  }

  String getSelectedGenresText() {
    List<String> parts = [];

    if (_selectedDrawerGenreIds.isNotEmpty) {
      final selectedGenres = _genres
          .where((g) => _selectedDrawerGenreIds.contains(g.id))
          .map((g) => g.name)
          .toList();

      if (selectedGenres.isNotEmpty) {
        parts.add(selectedGenres.join(', '));
      }
    }

    if (_selectedCountries.isNotEmpty) {
      parts.add(_selectedCountries.join(', '));
    }

    if (parts.isEmpty) {
      return 'Feature films';
    }

    return parts.join(' - ');
  }
}
