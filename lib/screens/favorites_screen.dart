import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/api_constants.dart';
import '../providers/movie_provider.dart'; // Import MovieProvider
import '../models/genre.dart';
import '../models/movie.dart';
import '../providers/downloads_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/watchlist_provider.dart';
import 'my_list_see_all_screen.dart'; // Import the enum

enum SortOption { byName, byDateAdded }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedGenreId; // null for "All Genres"
  List<Genre> _availableGenres = [];
  SortOption _currentSortOption =
      SortOption.byDateAdded; // Giữ lại logic sắp xếp
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _availableGenres = context.read<MovieProvider>().genres;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
    _tabController.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear(); // This will trigger _onSearchChanged
      _selectedGenreId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch MovieProvider for genres
    _availableGenres = context.watch<MovieProvider>().genres;

    // Phân loại phim và TV show
    final allFavorites = context.watch<FavoritesProvider>().favorites;
    final favoriteMovies =
        allFavorites.where((m) => m.mediaType == 'movie').toList();
    final favoriteTvShows =
        allFavorites.where((m) => m.mediaType == 'tv').toList();

    // Lấy danh sách gốc từ providers
    List<Movie> originalDownloads =
        context.watch<DownloadsProvider>().downloadedMovies;
    List<Movie> originalFavorites =
        context.watch<FavoritesProvider>().favorites;
    List<Movie> originalWatchlist =
        context.watch<WatchlistProvider>().watchlistMovies;

    // Sắp xếp danh sách gốc dựa trên tùy chọn đã chọn
    List<Movie> allDownloads = _sortMovies(originalDownloads);
    List<Movie> allFavoriteMovies = _sortMovies(favoriteMovies); // Đã phân loại
    List<Movie> allFavoriteTvShows =
        _sortMovies(favoriteTvShows); // Đã phân loại

    // --- Logic lọc ---
    // (Phần còn lại của logic lọc sẽ hoạt động trên các danh sách đã được sắp xếp và phân loại)
    // ...

    // final allDownloads = context.watch<DownloadsProvider>().downloadedMovies;
    // final allFavorites = context.watch<FavoritesProvider>().favorites;
    // final allWatchlist = context.watch<WatchlistProvider>().watchlistMovies;
    final allWatchlistMovies = _sortMovies(
        originalWatchlist.where((m) => m.mediaType == 'movie').toList());
    final allWatchlistTvShows = _sortMovies(
        originalWatchlist.where((m) => m.mediaType == 'tv').toList());

    List<Movie> filteredDownloads = [];
    List<Movie> filteredFavoriteMovies = [];
    List<Movie> filteredFavoriteTvShows = [];
    List<Movie> filteredWatchlistMovies = [];
    List<Movie> filteredWatchlistTvShows = [];

    // --- Apply Search Filter ---
    final List<Movie> searchFilteredDownloads = _searchQuery.isEmpty
        ? allDownloads
        : allDownloads
            .where((movie) =>
                movie.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
    final List<Movie> searchFilteredFavoriteMovies = _searchQuery.isEmpty
        ? allFavoriteMovies
        : allFavoriteMovies
            .where((movie) =>
                movie.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
    final List<Movie> searchFilteredFavoriteTvShows = _searchQuery.isEmpty
        ? allFavoriteTvShows
        : allFavoriteTvShows
            .where((movie) =>
                movie.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final List<Movie> searchFilteredWatchlistMovies = _searchQuery.isEmpty
        ? allWatchlistMovies
        : allWatchlistMovies
            .where((m) =>
                m.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final List<Movie> searchFilteredWatchlistTvShows = _searchQuery.isEmpty
        ? allWatchlistTvShows
        : allWatchlistTvShows
            .where((m) =>
                m.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    // --- Apply Genre Filter ---
    filteredDownloads = _filterMoviesByGenre(searchFilteredDownloads);
    filteredFavoriteMovies = _filterMoviesByGenre(searchFilteredFavoriteMovies);
    filteredFavoriteTvShows =
        _filterMoviesByGenre(searchFilteredFavoriteTvShows);
    filteredWatchlistMovies =
        _filterMoviesByGenre(searchFilteredWatchlistMovies);
    filteredWatchlistTvShows =
        _filterMoviesByGenre(searchFilteredWatchlistTvShows);

    // Lấy phim nổi bật đầu tiên (nếu có)
    // Chỉ hiển thị phim nổi bật nếu không có tìm kiếm đang diễn ra
    final allFeaturedItems = [
      ...allDownloads,
      ...allFavoriteMovies,
      ...allWatchlistMovies,
      ...allFavoriteTvShows,
      ...allWatchlistTvShows
    ];

    final featuredMovie = _searchQuery.isEmpty && _selectedGenreId == null
        ? (allFeaturedItems.isNotEmpty ? allFeaturedItems.first : null)
        : null;

    return Scaffold(
      extendBodyBehindAppBar: true, // Allows body to go behind AppBar
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B124C), Color(0xFF5B2A9B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // === KHU VỰC HEADER MỚI ===
            Padding(
              padding: const EdgeInsets.only(
                  top: kToolbarHeight, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Tiêu đề "My List"
                  const Text(
                    'My List',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  // TabBar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.pinkAccent,
                    indicatorWeight: 3.0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontSize: 16),
                    tabs: const [Tab(text: 'Movies'), Tab(text: 'TV Shows')],
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  const SizedBox(height: 16),
                  // Thanh tìm kiếm và các bộ lọc khác
                  _buildSearchBar(context),
                  _buildGenreFilter(),
                  _buildSortOptions(),
                  _buildClearFiltersButton(),
                ],
              ),
            ),
            // TabBarView để hiển thị nội dung tương ứng
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab Movies
                  _buildTabContent(featuredMovie, filteredDownloads,
                      filteredFavoriteMovies, filteredWatchlistMovies),
                  // Tab TV Shows
                  _buildTabContent(null, [], filteredFavoriteTvShows,
                      filteredWatchlistTvShows),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget để xây dựng nội dung cho mỗi tab
  Widget _buildTabContent(Movie? featured, List<Movie> downloads,
      List<Movie> favorites, List<Movie> watchlist) {
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 40),
      children: [
        if (featured != null) _buildFeaturedMovie(context, featured),
        if (_searchQuery.isEmpty && _selectedGenreId == null)
          const SizedBox(height: 20),
        if (downloads.isNotEmpty) ...[
          _buildDownloadsSection(context, downloads),
          const SizedBox(height: 20),
        ],
        _buildFavoritesSection(context, favorites, "Favorite Items"),
        const SizedBox(height: 20),
        _buildWatchlistSection(context, watchlist, "Watchlist Items"),
      ],
    );
  }

  Widget _buildSectionSeparator(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2),
      ),
    );
  }

  // Hàm sắp xếp một danh sách phim
  List<Movie> _sortMovies(List<Movie> movies) {
    List<Movie> sortedList = List.from(movies);
    switch (_currentSortOption) {
      case SortOption.byName:
        sortedList.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.byDateAdded:
        sortedList = sortedList.reversed.toList();
        break;
    }
    return sortedList;
  }

  // === FEATURED MOVIE ===
  Widget _buildFeaturedMovie(BuildContext context, Movie movie) {
    final isMovie = movie.mediaType == 'movie';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () => context
                      .push(isMovie ? '/movie/${movie.id}' : '/tv/${movie.id}'),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl:
                            '${ApiConstants.imageBaseUrlOriginal}${movie.posterPath}',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 40),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            movie.title,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatGenresAndRuntime(movie),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.pinkAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // === DOWNLOADS SECTION ===
  Widget _buildDownloadsSection(BuildContext context, List<Movie> downloads) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Remove const
            children: [
              Text(
                'DOWNLOADS (Movies only)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  context.push(
                    '/my-list/see-all',
                    extra: {
                      'title': 'All Downloads',
                      'movies': downloads,
                      'listType': MyListType.downloads,
                    },
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (downloads.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No downloaded movies yet.',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            )
          else
            Column(
              children: downloads.map((movie) {
                return _buildDownloadItem(
                    context, movie, context.read<DownloadsProvider>());
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(
      BuildContext context, Movie movie, DownloadsProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: '${ApiConstants.imageBaseUrl}${movie.posterPath}',
            width: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          movie.title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatGenresAndRuntime(movie),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            _buildRatingStars(movie.voteAverage),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.play_circle_fill, color: Colors.pinkAccent),
              onPressed: () {
                final filePath = provider.getFilePath(movie.id);
                if (filePath != null) {
                  context.push('/play-local/${movie.id}',
                      extra: {'filePath': filePath, 'title': movie.title});
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.pinkAccent),
              onPressed: () => provider.removeDownload(movie),
            ),
          ],
        ),
      ),
    );
  }

  // === FAVORITES SECTION (MỚI) ===
  Widget _buildFavoritesSection(
      BuildContext context, List<Movie> favorites, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Remove const
            children: [
              Text(
                'Favorites', // Giữ nguyên tiêu đề nhỏ
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  context.push(
                    '/my-list/see-all',
                    extra: {
                      'title': title, // Dùng title được truyền vào
                      'movies': favorites,
                      'listType': MyListType.favorites,
                    },
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (favorites.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'This list is empty.', // Thông báo chung
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            )
          else
            Column(
              children: favorites.map((movie) {
                return _buildFavoriteItem(
                    context, movie, context.read<FavoritesProvider>());
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Widget cho một mục trong danh sách yêu thích (MỚI)
  Widget _buildFavoriteItem(
      BuildContext context, Movie movie, FavoritesProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () => context.push('/movie/${movie.id}'),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: '${ApiConstants.imageBaseUrl}${movie.posterPath}',
            width: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          movie.title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatGenresAndRuntime(movie),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            _buildRatingStars(movie.voteAverage),
          ],
        ),
        trailing: IconButton(
            icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
            onPressed: () => provider.toggleFavorite(movie)),
      ),
    );
  }

  // === WATCHLIST SECTION (MỚI) ===
  Widget _buildWatchlistSection(
      BuildContext context, List<Movie> watchlist, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Watchlist',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  context.push(
                    '/my-list/see-all',
                    extra: {
                      'title': title, // Dùng title được truyền vào
                      'movies': watchlist,
                      'listType': MyListType.watchlist,
                    },
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (watchlist.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'This list is empty.', // Thông báo chung
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            )
          else
            Column(
              children: watchlist.map((movie) {
                return _buildWatchlistItem(
                    context, movie, context.read<WatchlistProvider>());
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildWatchlistItem(
      BuildContext context, Movie movie, WatchlistProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () => context.push('/movie/${movie.id}'),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: '${ApiConstants.imageBaseUrl}${movie.posterPath}',
            width: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(movie.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_formatGenresAndRuntime(movie),
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            _buildRatingStars(movie.voteAverage),
          ],
        ),
        trailing: IconButton(
            icon: const Icon(Icons.bookmark_remove, color: Colors.pinkAccent),
            onPressed: () => provider.toggleWatchlist(movie)),
      ),
    );
  }

  // === SEARCH BAR ===
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search your movies...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.pinkAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  // === CLEAR FILTERS BUTTON ===
  Widget _buildClearFiltersButton() {
    final bool isFilterActive =
        _searchQuery.isNotEmpty || _selectedGenreId != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: isFilterActive
          ? Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 8),
                child: TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear Filters'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // === GENRE FILTER ===
  Widget _buildGenreFilter() {
    // Add "All Genres" option at the beginning
    final List<Genre> displayGenres = [
      Genre(id: 0, name: 'All Genres'), // Use 0 or a special ID for "All"
      ..._availableGenres,
    ];

    return Container(
      height: 40, // Height for the horizontal list of chips
      margin: const EdgeInsets.only(top: 12.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: displayGenres.length,
        itemBuilder: (context, index) {
          final genre = displayGenres[index];
          final bool isSelected = (_selectedGenreId == null && genre.id == 0) ||
              (_selectedGenreId == genre.id);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(genre.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedGenreId = (genre.id == 0) ? null : genre.id;
                  });
                }
              },
              selectedColor: Colors.pinkAccent,
              backgroundColor: Colors.white.withOpacity(0.1),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.pinkAccent : Colors.transparent,
                  width: 1.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // === SORT OPTIONS ===
  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          const Text("Sort by:", style: TextStyle(color: Colors.white70)),
          const SizedBox(width: 10),
          _buildSortChip('Date Added', SortOption.byDateAdded),
          const SizedBox(width: 10),
          _buildSortChip('Name (A-Z)', SortOption.byName),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, SortOption option) {
    final bool isSelected = _currentSortOption == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentSortOption = option;
          });
        }
      },
      selectedColor: Colors.pinkAccent,
      backgroundColor: Colors.white.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.pinkAccent : Colors.transparent,
          width: 1.5,
        ),
      ),
    );
  }

  List<Movie> _filterMoviesByGenre(List<Movie> movies) {
    if (_selectedGenreId == null) return movies;
    return movies
        .where((movie) =>
            movie.genres?.any((g) => g.id == _selectedGenreId) ?? false)
        .toList();
  }

  // === Helper: Rating Stars ===
  Widget _buildRatingStars(double voteAverage) {
    final rating = voteAverage / 2; // Convert 10-point scale to 5-point
    final List<Widget> stars = List.generate(5, (index) {
      // Explicitly create a List<Widget>
      return Icon(
        index < rating.floor()
            ? Icons.star
            : index < rating
                ? Icons.star_half
                : Icons.star_border,
        color: Colors.amber,
        size: 16,
      );
    });

    stars.add(const SizedBox(width: 4));
    stars.add(Text(voteAverage.toStringAsFixed(1),
        style: const TextStyle(color: Colors.white70, fontSize: 12)));

    return Row(children: stars);
  }

  // === Helper: genres + runtime
  String _formatGenresAndRuntime(Movie movie) {
    String genreName = '';
    if (movie.genres?.isNotEmpty ?? false) {
      // Find the actual genre name from the available genres list
      final firstGenreId = movie.genres!.first.id;
      final foundGenre = _availableGenres.firstWhere(
        (g) => g.id == firstGenreId,
        orElse: () => Genre(id: 0, name: ''), // Fallback an toàn
      );
      genreName = foundGenre.name; // Sẽ là '' nếu không tìm thấy
    }
    final runtime = movie.runtime != null
        ? '${movie.runtime! ~/ 60}h ${movie.runtime! % 60}m'
        : '';
    return '$genreName ${runtime.isNotEmpty ? '• $runtime' : ''}';
  }
}
