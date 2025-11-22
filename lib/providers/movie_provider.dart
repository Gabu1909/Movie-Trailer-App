import 'package:flutter/material.dart';
import 'dart:async';
import '../core/api/api_service.dart';
import '../core/models/actor_detail.dart';
import '../core/models/genre.dart';
import '../core/models/movie.dart';
import '../core/models/filter_helper.dart';
import 'notification_provider.dart';

class MovieProvider with ChangeNotifier, WidgetsBindingObserver {
  final ApiService _apiService;
  final NotificationProvider? _notificationProvider;

  List<Movie> _popularMovies = [];
  List<Movie> _trendingMovies = [];
  List<Movie> _upcomingMovies = [];
  List<Movie> _kidsMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _nowPlayingMovies = [];
  List<Movie> _weeklyTrendingMovies = [];
  List<Movie> _searchedMovies = [];
  bool _isDisposed = false;
  List<Genre> _genres = [];

  final Map<int, List<Movie>> _cachedGenreMovies = {};

  bool _isLoading = true;
  bool _isTrendingLoading = false;
  bool _isFilterLoading = false;
  Timer? _trendingRefreshTimer;
  bool _isFetchingMoreUpcoming = false;
  int _upcomingPage = 1;
  bool _hasMoreUpcoming = true;

  int _selectedGenreIndex = 0;

  List<int> _selectedDrawerGenreIds = [];
  List<String> _selectedCountries = [];

  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get upcomingMovies => _upcomingMovies;
  List<Movie> get kidsMovies => _kidsMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get nowPlayingMovies => _nowPlayingMovies;
  List<Movie> get weeklyTrendingMovies => _weeklyTrendingMovies;
  List<Movie> get searchedMovies => _searchedMovies;
  List<Genre> get genres => _genres;
  bool get isLoading => _isLoading;
  bool get isTrendingLoading => _isTrendingLoading;
  bool get isFilterLoading => _isFilterLoading;
  bool get isFetchingMoreUpcoming => _isFetchingMoreUpcoming;

  int get selectedGenreIndex => _selectedGenreIndex;
  List<int> get selectedDrawerGenreIds => _selectedDrawerGenreIds;
  List<String> get selectedCountries => _selectedCountries;

  List<Movie> get topRatedSorted {
    final list = [..._topRatedMovies];
    list.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    return list;
  }

  final Completer<void> _initializationCompleter = Completer<void>();
  Future<void> get initializationComplete => _initializationCompleter.future;

  MovieProvider(this._apiService, [this._notificationProvider]) {
    WidgetsBinding.instance.addObserver(this);
    fetchAllData();
    _startTrendingTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _trendingRefreshTimer?.cancel();
      debugPrint('⏸️ Timer paused - app in background');
    } else if (state == AppLifecycleState.resumed) {
      _startTrendingTimer();
      debugPrint('▶️ Timer resumed - app in foreground');
    }
  }

  Future<void> fetchAllData() async {
    _isLoading = true;
    _safeNotifyListeners();
    _isTrendingLoading = true;
    _safeNotifyListeners();

    _cachedGenreMovies.clear();

    try {
      final results = await Future.wait([
        _apiService.getPopularMovies(),
        _apiService.getUpcomingMovies(),
        _apiService.getMoviesByGenre('10751'), 
        _apiService.getGenres(),
        _apiService.getTopRatedMovies(),
        _apiService.getNowPlayingMovies(),
        _apiService.getTrendingMoviesOfWeek(),
      ]);
      _popularMovies = results[0] as List<Movie>;
      _trendingMovies = _popularMovies;

      final upcoming = results[1] as List<Movie>;
      upcoming.sort((a, b) {
        if (a.releaseDate == null) return 1;
        if (b.releaseDate == null) return -1;
        return b.releaseDate!.compareTo(a.releaseDate!);
      });
      _upcomingMovies = upcoming;
      _kidsMovies = results[2] as List<Movie>;
      _genres = results[3] as List<Genre>;
      _topRatedMovies = results[4] as List<Movie>;
      _nowPlayingMovies = results[5] as List<Movie>;
      _weeklyTrendingMovies = results[6] as List<Movie>;

      _cachedGenreMovies[0] = _popularMovies;

      _createActorNotifications();
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
    }

    _isLoading = false;
    _isTrendingLoading = false;
    _safeNotifyListeners();
  }

  Future<void> _createActorNotifications() async {
    if (_notificationProvider == null) return;

    try {
      final popularActors = await _apiService.getPopularActors();
      for (final actor in popularActors.take(3)) {
        final ActorDetail actorDetail =
            await _apiService.getActorDetails(actor.id);
        final List<Movie> movieCredits = actorDetail.movieCredits;
        if (movieCredits.isEmpty) continue;

        movieCredits.sort((a, b) {
          final dateA = a.releaseDate;
          final dateB = b.releaseDate;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });

        final latestMovie = movieCredits.first;
        _notificationProvider.addActorInNewMovieNotification(
            actor, latestMovie);
      }
    } catch (e) {
      debugPrint('Error creating actor notifications: $e');
    }
  }

  Future<void> searchMovies(String query) async {
    _isLoading = true;
    _searchedMovies = [];
    _safeNotifyListeners();
    if (query.isNotEmpty) {
      try {
        _searchedMovies = await _apiService.searchMovies(query);
      } catch (e) {
        debugPrint('Error searching movies: $e');
      }
    }
    _isLoading = false;
    _safeNotifyListeners();
  }

  Future<void> fetchTrendingMoviesByGenre(int? genreId) async {
    _isTrendingLoading = true;
    _safeNotifyListeners();

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
    _safeNotifyListeners();
  }

  Future<void> selectGenre(int index, int? genreId) async {
    _selectedGenreIndex = index;
    await fetchTrendingMoviesByGenre(genreId);
  }

  void _startTrendingTimer() {
    _trendingRefreshTimer?.cancel();

    _trendingRefreshTimer =
        Timer.periodic(const Duration(minutes: 15), (timer) {
      debugPrint('⏰ Tự động làm mới danh sách phim thịnh hành...');

      int? genreId;
      if (_selectedGenreIndex > 0 && _genres.isNotEmpty) {
        genreId = _genres[_selectedGenreIndex - 1].id;
      }
      fetchTrendingMoviesByGenre(genreId);
    });
  }

  Future<void> fetchMoreUpcomingMovies() async {
    if (_isFetchingMoreUpcoming || !_hasMoreUpcoming) return;

    _isFetchingMoreUpcoming = true;
    _safeNotifyListeners();

    try {
      _upcomingPage++;
      final moreMovies =
          await _apiService.getUpcomingMovies(page: _upcomingPage);
      if (moreMovies.isNotEmpty) {
        moreMovies.sort((a, b) {
          if (a.releaseDate == null) return 1;
          if (b.releaseDate == null) return -1;
          return b.releaseDate!.compareTo(a.releaseDate!);
        });
        _upcomingMovies.addAll(moreMovies);
      } else {
        _hasMoreUpcoming = false;
      }
    } catch (e) {
      debugPrint('Error fetching more upcoming movies: $e');
      _upcomingPage--;
    } finally {
      _isFetchingMoreUpcoming = false;
      _safeNotifyListeners();
    }
  }

  void toggleDrawerGenre(int genreId) {
    if (_selectedDrawerGenreIds.contains(genreId)) {
      _selectedDrawerGenreIds.remove(genreId);
    } else {
      _selectedDrawerGenreIds.add(genreId);
    }
    _safeNotifyListeners();
  }

  void toggleCountry(String country) {
    if (_selectedCountries.contains(country)) {
      _selectedCountries.remove(country);
    } else {
      _selectedCountries.add(country);
    }
    _safeNotifyListeners();
  }

  bool isGenreSelected(int genreId) {
    return _selectedDrawerGenreIds.contains(genreId);
  }

  bool isCountrySelected(String country) {
    return _selectedCountries.contains(country);
  }

  void clearDrawerGenres() {
    _selectedDrawerGenreIds.clear();
    _selectedCountries.clear();
    _safeNotifyListeners();
  }

  String getSelectedGenresText() {
    if (_selectedDrawerGenreIds.isEmpty && _selectedCountries.isEmpty) {
      return 'All Movies';
    }

    final genreNames = _genres
        .where((g) => _selectedDrawerGenreIds.contains(g.id))
        .map((g) => g.name)
        .toList();

    final parts = <String>[];
    if (genreNames.isNotEmpty) {
      parts.add(genreNames.join(', '));
    }
    if (_selectedCountries.isNotEmpty) {
      parts.add(_selectedCountries.join(', '));
    }

    return parts.join(' - ');
  }

  Future<List<Movie>> getMoviesByFilter() async {
    _isFilterLoading = true;
    _safeNotifyListeners();

    try {
      final genreIds = _selectedDrawerGenreIds.join(',');
      final countryCodes =
          FilterHelper.getCountryCodes(_selectedCountries.toSet());

      if (genreIds.isEmpty && countryCodes.isEmpty) {
        _isFilterLoading = false;
        _safeNotifyListeners();
        return _popularMovies;
      }

      final movies = await _apiService.discoverMovies(genreIds, countryCodes);

      _isFilterLoading = false;
      _safeNotifyListeners();
      return movies;
    } catch (e) {
      _isFilterLoading = false;
      _safeNotifyListeners();
      return [];
    }
  }

  Future<List<Movie>> getPopularTVShows() async {
    try {
      return await _apiService.getPopularTVShows();
    } catch (e) {
      debugPrint('Error fetching TV shows: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _trendingRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}
