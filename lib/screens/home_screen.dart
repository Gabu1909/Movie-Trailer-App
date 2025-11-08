import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/movie_provider.dart';
import '../widgets/trending_movie_card.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/trending_movie_card_placeholder.dart';
import '../theme/constants.dart';
import '../api/api_service.dart';
import '../models/genre.dart';
import '../widgets/movie_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  PageController? _pageController;
  int _currentPage = 10000;
  int _actualMovieIndex = 0;
  Timer? _autoSlideTimer;

  int? _hoveredGenreId;

  late AnimationController _bgController;
  late Animation<Alignment> _beginAlignmentAnimation;
  late Animation<Alignment> _endAlignmentAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _beginAlignmentAnimation =
        AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight)
            .animate(_bgController);
    _endAlignmentAnimation =
        AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft)
            .animate(_bgController);

    _initializePageController();
    _startAutoSlideTimer();
  }

  void _initializePageController() {
    _pageController?.dispose();
    _pageController = PageController(
      viewportFraction: 0.65,
      initialPage: 10000,
    );
    _pageController!.addListener(() {
      if (_pageController!.page != null) {
        int next = _pageController!.page!.round();
        if (_currentPage != next) {
          setState(() {
            _currentPage = next;
            final movieProvider =
                Provider.of<MovieProvider>(context, listen: false);
            if (movieProvider.trendingMovies.isNotEmpty) {
              _actualMovieIndex =
                  _currentPage % movieProvider.trendingMovies.length;
            }
          });
        }
      }
    });
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController?.hasClients ?? false) {
        final movieProvider =
            Provider.of<MovieProvider>(context, listen: false);
        if (movieProvider.trendingMovies.isEmpty) return;
        _pageController!.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoSlideTimer() {
    _autoSlideTimer?.cancel();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pageController?.dispose();
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Scaffold(
          key: _scaffoldKey,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF12002F),
                  Color(0xFF3A0CA3),
                  Color(0xFF7209B7),
                ],
                begin: _beginAlignmentAnimation.value,
                end: _endAlignmentAnimation.value,
              ),
            ),
            child: child,
          ),
          drawer: _buildDrawer(context),
        );
      },
      child: Consumer<MovieProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomAppBar(onMenuPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  }),
                  _buildTrendingSection(context, provider),
                  if (provider.upcomingMovies.isNotEmpty)
                    MovieList(
                        title: 'Coming Soon', movies: provider.upcomingMovies),
                  if (provider.topRatedMovies.isNotEmpty)
                    MovieList(
                        title: 'Best for Kids',
                        movies: provider.topRatedMovies),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final genres = context.read<MovieProvider>().genres;
    final List<String> countries = [
      'USA',
      'India',
      'Korea',
      'Japan',
      'China',
      'Vietnam'
    ];

    return Drawer(
      backgroundColor: const Color(0xFF1A0933),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF3A0CA3),
            ),
            child: Text(
              'PuTa Movies',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Feature Film
          ListTile(
            leading: const Icon(Icons.movie_filter, color: Colors.white70),
            title: const Text('Feature film',
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              final provider = context.read<MovieProvider>();
              provider.clearDrawerGenres();

              context.pop();
              context.push('/see-all', extra: {
                'title': 'Feature films',
                'movies': provider.popularMovies
              });
            },
          ),

          // TV Shows
          ListTile(
            leading: const Icon(Icons.tv, color: Colors.white70),
            title:
                const Text('TV Shows', style: TextStyle(color: Colors.white)),
            onTap: () async {
              final provider = context.read<MovieProvider>();
              provider.clearDrawerGenres();

              final tvShows = await provider.getPopularTVShows();

              if (!context.mounted) return;
              context.pop();
              context.push('/see-all',
                  extra: {'title': 'TV Shows', 'movies': tvShows});
            },
          ),

          const Divider(color: Colors.white24),

          // Genres Section
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Genres',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                ),
                TextButton(
                  onPressed: () {
                    context.read<MovieProvider>().clearDrawerGenres();
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: genres
                  .map((genre) => _buildDrawerChip(context, genre))
                  .toList(),
            ),
          ),

          const Divider(color: Colors.white24),

          // Countries Section
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Countries',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: countries
                  .map((country) => _buildCountryDrawerChip(context, country))
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Apply Filters Button
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Consumer<MovieProvider>(
              builder: (context, provider, child) {
                final hasFilters = provider.selectedDrawerGenreIds.isNotEmpty ||
                    provider.selectedCountries.isNotEmpty;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final movies =
                          await provider.getMoviesForSelectedGenres();
                      final title = provider.getSelectedGenresText();

                      if (!context.mounted) return;
                      context.pop();
                      context.push('/see-all',
                          extra: {'title': title, 'movies': movies});
                    },
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Apply Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasFilters
                          ? Colors.pinkAccent
                          : Colors.pinkAccent.withOpacity(0.6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: hasFilters ? 8 : 2,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerChip(BuildContext context, Genre genre) {
    final provider = context.watch<MovieProvider>();
    final isSelected = provider.isGenreSelected(genre.id);
    final isHovering = _hoveredGenreId == genre.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredGenreId = genre.id),
      onExit: (_) => setState(() => _hoveredGenreId = null),
      child: InkWell(
        onTap: () {
          provider.toggleDrawerGenre(genre.id);
        },
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.pinkAccent
                : (isHovering
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected
                  ? Colors.pinkAccent
                  : (isHovering
                      ? Colors.pinkAccent.withOpacity(0.7)
                      : Colors.transparent),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                genre.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check, color: Colors.white, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryDrawerChip(BuildContext context, String country) {
    final provider = context.watch<MovieProvider>();
    final isSelected = provider.isCountrySelected(country);

    return InkWell(
      onTap: () {
        provider.toggleCountry(country);
      },
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.pinkAccent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              country,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check, color: Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection(BuildContext context, MovieProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lets Explore',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        color: Colors.white.withOpacity(0.05),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'TRENDING',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.trending_up_rounded,
                              color: kGreyColor,
                              size: 20,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final movies = provider.trendingMovies;
                      final title = 'Trending';

                      context.push('/see-all', extra: {
                        'title': title,
                        'movies': movies,
                      });
                    },
                    child: Text(
                      'See All',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildGenreTabs(context, provider.genres),
        SizedBox(
          height: 380,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: provider.isTrendingLoading
                    ? PageView.builder(
                        key: const ValueKey('shimmer_loader'),
                        controller: PageController(viewportFraction: 0.65),
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          final isCenter = index == 1;
                          return AnimatedScale(
                            scale: isCenter ? 1.0 : 0.8,
                            duration: const Duration(milliseconds: 400),
                            child: const AnimatedOpacity(
                                opacity: 1.0,
                                duration: Duration(milliseconds: 400),
                                child: TrendingMovieCardPlaceholder()),
                          );
                        })
                    : NotificationListener<ScrollNotification>(
                        key: ValueKey(provider.selectedGenreIndex),
                        onNotification: (notification) {
                          if (notification is UserScrollNotification) {
                            _stopAutoSlideTimer();
                          } else if (notification is ScrollEndNotification) {
                            _startAutoSlideTimer();
                          }
                          return true;
                        },
                        child: PageView.builder(
                          controller: _pageController!,
                          itemCount:
                              provider.trendingMovies.isEmpty ? 0 : 1000000,
                          itemBuilder: (context, index) {
                            return AnimatedBuilder(
                              animation: _pageController!,
                              builder: (context, child) {
                                double pageOffset = 0;
                                if (_pageController!.position.haveDimensions) {
                                  pageOffset =
                                      index - (_pageController!.page ?? 0);
                                }
                                if (provider.trendingMovies.isEmpty) {
                                  return const Center(
                                      child: Text(
                                          "No movies found for this genre."));
                                }
                                final movieIndex =
                                    index % provider.trendingMovies.length;
                                return TrendingMovieCard(
                                  movie: provider.trendingMovies[movieIndex],
                                  isCenterItem: movieIndex == _actualMovieIndex,
                                  scrollOffset: pageOffset,
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
              Positioned(
                bottom: 42,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: provider.isTrendingLoading ? 0.0 : 1.0,
                  child: Center(
                    child: _buildWormIndicator(
                      itemCount: provider.trendingMovies.length.clamp(0, 5),
                      activeIndex: _actualMovieIndex % 5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenreTabs(BuildContext context, List<Genre> genres) {
    List<dynamic> displayGenres = [
      Genre(id: 0, name: 'Popular'),
      ...genres.take(4)
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 12.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: displayGenres.length,
        itemBuilder: (context, index) {
          final genre = displayGenres[index];
          bool isSelected =
              context.watch<MovieProvider>().selectedGenreIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(genre.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _actualMovieIndex = 0;
                    _currentPage = 10000;
                  });
                  _initializePageController();
                  context.read<MovieProvider>().selectGenre(index, genre.id);
                  _startAutoSlideTimer();
                }
              },
              selectedColor: const Color(0xFFE91E63),
              backgroundColor: Colors.deepPurple[400],
              labelStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWormIndicator(
      {required int itemCount, required int activeIndex}) {
    if (itemCount == 0) return const SizedBox.shrink();

    const double dotSize = 8.0;
    const double dotSpacing = 12.0;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(itemCount, (index) {
            return Container(
              width: dotSize,
              height: dotSize,
              margin:
                  EdgeInsets.symmetric(horizontal: (dotSpacing - dotSize) / 2),
              decoration: BoxDecoration(
                color: kGreyColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          width: dotSize,
          height: dotSize,
          margin: EdgeInsets.only(left: activeIndex * dotSpacing),
          decoration: BoxDecoration(
            color: kPrimaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
