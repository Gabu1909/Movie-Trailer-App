import 'dart:ui';
import 'dart:async'; // Import để sử dụng Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/movie_provider.dart';
import '../../widgets/lists/movie_list.dart';
import '../../widgets/cards/trending_movie_card.dart'; // Import widget mới
import '../../widgets/cards/trending_movie_card_placeholder.dart'; // Import placeholder
import '../../widgets/cards/kids_movie_card.dart'; // Import mới
import '../../widgets/cards/ranked_movie_card.dart'; // Import còn thiếu
import '../../widgets/cards/cinematic_wide_card.dart'; // Import mới
import '../../widgets/navigation/custom_app_bar.dart'; // Import CustomAppBar
import '../../theme/constants.dart';
import '../../models/genre.dart';
import 'see_all_screen.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/text/section_header.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _hoveredGenreId;
  late AnimationController _bgController;
  late Animation<Alignment> _beginAlignmentAnimation;
  late Animation<Alignment> _endAlignmentAnimation;

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
      viewportFraction: 0.70,
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
          curve: Curves.easeOutCubic,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(context),
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              color: isDarkMode ? null : Theme.of(context).scaffoldBackgroundColor,
              gradient: isDarkMode
                  ? LinearGradient(
                      colors: const [
                        Color(0xFF0D0221),
                        Color(0xFF240046),
                        Color(0xFF3A0CA3),
                        Color(0xFF5A189A),
                      ],
                      begin: _beginAlignmentAnimation.value,
                      end: _endAlignmentAnimation.value,
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    )
                  : null,
              ),
            child: child,
          ),
        );
      },
      child: Consumer<MovieProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow circle
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFF006E).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Inner gradient circle
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF006E),
                              Color(0xFFFF6EC7),
                              Color(0xFFFFABD5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF006E).withOpacity(0.6),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF6EC7).withOpacity(0.4),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFF006E), Color(0xFFFF6EC7)],
                    ).createShader(bounds),
                    child: const Text(
                      'Loading Movies...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please wait',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchAllData(),
            color: const Color(0xFFFF006E),
            backgroundColor: Colors.white,
            strokeWidth: 3,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomAppBar(onMenuPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  }),
                  _buildTrendingSection(context, provider),
                  const SizedBox(height: 24), // Tăng khoảng cách một chút

                  // 1. TOP RATED (Màu Vàng Gold)
                  if (provider.topRatedSorted.isNotEmpty) ...[
                    const SizedBox(height: 10), // Khoảng cách nhỏ
                    SectionHeader(
                      title: 'Top Rated',
                      accentColors: const [Color(0xFFFFD700), Color(0xFFFF8F00)], // Gradient Vàng Cam
                      onSeeAll: () => context.push('/see-all', extra: {'title': 'Top Rated', 'movies': provider.topRatedSorted}),
                    ),
                    const SizedBox(height: 16),

                    // 👇 Thay ListView bằng Column để xếp dọc
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0), // Padding 2 bên lề
                      child: Column(
                        children: provider.topRatedSorted
                            .take(3) // 👈 CHỈ LẤY 3 PHIM ĐẦU TIÊN
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                          int index = entry.key;
                          var movie = entry.value;
                          return RankedMovieCard(
                            movie: movie,
                            index: index,
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // 2. BEST FOR KIDS (Màu Neon Cyan-Pink)
                  if (provider.kidsMovies.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Best for Kids',
                      accentColors: const [Colors.cyanAccent, Colors.pinkAccent], // Gradient Xanh Hồng
                      onSeeAll: () => context.push('/see-all', extra: {'title': 'Best for Kids', 'movies': provider.kidsMovies}),
                    ),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: <Color>[
                            Colors.white.withOpacity(0.0),
                            Colors.white,
                            Colors.white,
                            Colors.white.withOpacity(0.0)
                          ],
                          stops: const [0.0, 0.05, 0.95, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: SizedBox(
                        height:
                            260, // Tăng chiều cao cho thẻ Kids mới (vì có shadow và viền)
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.kidsMovies.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: KidsMovieCard(
                                  movie: provider.kidsMovies[index]),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // 3. RECOMMENDATIONS (Màu Tím Xanh)
                  if (provider.weeklyTrendingMovies.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Recommendations',
                      accentColors: const [Color(0xFFD96FF8), Color(0xFF40C9FF)], // Gradient Tím Xanh
                      onSeeAll: () => context.push('/see-all', extra: {'title': 'Recommendations', 'movies': provider.weeklyTrendingMovies}),
                    ),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: <Color>[
                            Colors.white.withOpacity(0.0),
                            Colors.white,
                            Colors.white,
                            Colors.white.withOpacity(0.0)
                          ],
                          stops: const [0.0, 0.05, 0.95, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: SizedBox(
                        height: 250, // Chiều cao cho thẻ Cinematic (Backdrop)
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.weeklyTrendingMovies.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: CinematicWideCard(
                                  movie: provider
                                      .weeklyTrendingMovies[index]), // 🔥 Dùng Widget mới
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF240046),
              const Color(0xFF1A0933),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Enhanced Drawer Header
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5A189A), Color(0xFF3A0CA3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Image.network(
                        'https://www.transparenttextures.com/patterns/45-degree-fabric-light.png',
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF006E), Color(0xFFFF6EC7)],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF006E).withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.movie_filter_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'PuTa Movies',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover Amazing Content',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Feature Film
            _buildDrawerMenuItem(
              context,
              icon: Icons.movie_filter_rounded,
              title: 'Feature Films',
              subtitle: 'Browse all movies',
              onTap: () async {
                final provider = context.read<MovieProvider>();
                provider.clearDrawerGenres();
                Navigator.of(context).pop();
                await Future.delayed(const Duration(milliseconds: 300));
                if (!context.mounted) return;
                await provider.initializationComplete;
                if (!context.mounted) return;
                final movies = provider.popularMovies;
                if (movies.isEmpty) {
                  if (context.mounted) {
                    UIHelpers.showWarningSnackBar(context, 'No movies found');
                  }
                  return;
                }
                if (context.mounted) {
                  context.push('/see-all',
                      extra: {'title': 'Feature Films', 'movies': movies});
                }
              },
            ),

            // TV Shows
            _buildDrawerMenuItem(
              context,
              icon: Icons.live_tv_rounded,
              title: 'TV Shows',
              subtitle: 'Popular series',
              onTap: () async {
                final provider = context.read<MovieProvider>();
                provider.clearDrawerGenres();
                Navigator.of(context).pop();
                await Future.delayed(const Duration(milliseconds: 300));
                if (!context.mounted) return;
                UIHelpers.showLoadingDialog(context);
                try {
                  final tvShows = await provider.getPopularTVShows();
                  if (!context.mounted) return;
                  UIHelpers.hideLoadingDialog(context);
                  if (tvShows.isEmpty) {
                    if (context.mounted) {
                      UIHelpers.showWarningSnackBar(
                          context, 'No TV shows found');
                    }
                    return;
                  }
                  if (context.mounted) {
                    context.push('/see-all',
                        extra: {'title': 'TV Shows', 'movies': tvShows});
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  UIHelpers.hideLoadingDialog(context);
                  UIHelpers.showErrorSnackBar(
                      context, 'Error loading TV shows: $e');
                }
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child:
                  Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
            ),

            // Genres Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF006E), Color(0xFFFF6EC7)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.category_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Genres',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      context.read<MovieProvider>().clearDrawerGenres();
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        color: Color(0xFFFF6EC7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child:
                  Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
            ),

            // Countries Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5A189A), Color(0xFF3A0CA3)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.public_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Countries',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
              padding: const EdgeInsets.all(16.0),
              child: Consumer<MovieProvider>(
                builder: (context, provider, child) {
                  final hasFilters =
                      provider.selectedDrawerGenreIds.isNotEmpty ||
                          provider.selectedCountries.isNotEmpty;

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: hasFilters
                          ? const LinearGradient(
                              colors: [Color(0xFFFF006E), Color(0xFFFF6EC7)],
                            )
                          : null,
                      boxShadow: hasFilters
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF006E).withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final movieProvider =
                            Provider.of<MovieProvider>(context, listen: false);
                        final navigator =
                            Navigator.of(context, rootNavigator: true);
                        Navigator.of(context).pop();
                        await Future.delayed(const Duration(milliseconds: 300));
                        try {
                          final movies =
                              await movieProvider.getMoviesByFilter();
                          final title = movieProvider.getSelectedGenresText();
                          if (movies.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'No movies found.\nTry different filters.'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 3),
                              ),
                            );
                            return;
                          }
                          navigator.push(
                            MaterialPageRoute(
                              builder: (context) => SeeAllScreen(
                                title: title,
                                movies: movies,
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.filter_list_rounded, size: 22),
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
            const SizedBox(height: 16),
          ],
        ),
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

  Widget _buildDrawerMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF006E), Color(0xFFFF6EC7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Widget cho toàn bộ phần "Trending"
  Widget _buildTrendingSection(BuildContext context, MovieProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- PHẦN TIÊU ĐỀ MỚI ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Subtitle "LETS EXPLORE"
              Text(
                'LETS EXPLORE', // Viết hoa toàn bộ
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0, // Giãn chữ rộng ra cho sang
                ),
              ),

              const SizedBox(height: 4),

              // 2. Title "TRENDING" + Icon + See All
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Chữ TRENDING với hiệu ứng Gradient Text
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Colors.white,
                        Color(0xFFFF006E), // Màu hồng neon
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: const Text(
                      'TRENDING',
                      style: TextStyle(
                        color: Colors.white, // Màu nền cho shader
                        fontSize: 35, // Tăng kích thước lên to hẳn
                        fontWeight: FontWeight.w900, // Siêu đậm
                        height: 1.0,
                        fontStyle: FontStyle.italic, // Nghiêng cho động
                        shadows: [
                          // Bóng hồng nhẹ xung quanh
                          Shadow(
                            color: Color(0xFFFF006E),
                            blurRadius: 20,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Icon mũi tên đi lên (Cũng phát sáng)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF006E).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFFFF006E),
                      size: 24,
                    ),
                  ),

                  const Spacer(),

                  // Nút See All (Đã làm đẹp ở bước trước)
                  // 👇 NÚT SEE ALL MỚI (STYLE NEON)
                  GestureDetector(
                    onTap: () {
                      context.push('/see-all', extra: {
                        'title': 'Trending',
                        'movies': provider.trendingMovies
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        // Nền hồng rất nhạt (Glass tint)
                        color: const Color(0xFFFF006E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        // Viền hồng neon
                        border: Border.all(
                          color: const Color(0xFFFF006E).withOpacity(0.5),
                          width: 1,
                        ),
                        // Hiệu ứng phát sáng nhẹ (Glow)
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF006E).withOpacity(0.25),
                            blurRadius: 12,
                            spreadRadius: -2,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFFFF006E), // Chữ màu hồng neon
                              fontSize: 12,
                              fontWeight: FontWeight.w800, // Đậm hơn
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 6),
                          // Icon mũi tên nhỏ
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFFFF006E),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Các tab thể loại (Genre)
        _buildGenreTabs(context, provider.genres),

        // Carousel (PageView) + overlay indicator
        SizedBox(
          height: 380,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                duration: const Duration(milliseconds: 500),
                child: provider.isTrendingLoading
                    ? PageView.builder(
                        key: const ValueKey('shimmer_loader'),
                        // SỬA LỖI: Tạo một PageController riêng cho shimmer.
                        // Không dùng chung _pageController của state.
                        controller: PageController(viewportFraction: 0.65),
                        itemCount: 5, // Hiển thị 5 placeholder
                        itemBuilder: (context, index) {
                          // Áp dụng hiệu ứng scale và opacity giống như card thật
                          // để giao diện chờ trông nhất quán.
                          // Ở đây, chúng ta giả định chỉ có item giữa là "active".
                          final isCenter = index == 1;
                          return AnimatedScale(
                            scale: isCenter ? 1.0 : 0.8,
                            duration: const Duration(milliseconds: 400),
                            child: const AnimatedOpacity(
                                opacity: 1.0, // Giữ opacity để thấy shimmer
                                duration: Duration(milliseconds: 400),
                                child: TrendingMovieCardPlaceholder()),
                          );
                        })
                    : NotificationListener<ScrollNotification>(
                        key: ValueKey(provider
                            .selectedGenreIndex), // Key để nhận diện sự thay đổi danh sách
                        onNotification: (notification) {
                          if (notification is UserScrollNotification) {
                            _stopAutoSlideTimer();
                          } else if (notification is ScrollEndNotification) {
                            _startAutoSlideTimer();
                          }
                          return true;
                        },
                        child: PageView.builder(
                          controller:
                              _pageController!, // Sử dụng controller đã được khởi tạo
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

              // Page indicator overlay
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
                    ), // Đã sửa lỗi cú pháp ở đây
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget cho các tab thể loại
  Widget _buildGenreTabs(BuildContext context, List<Genre> genres) {
    // Thêm "Popular" vào đầu danh sách
    List<dynamic> displayGenres = [
      Genre(id: 0, name: 'Popular'), // Dùng class Genre cho đồng nhất
      ...genres.take(4) // Lấy 4 thể loại đầu tiên từ API
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 12.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: displayGenres.length,
        itemBuilder: (context, index) {
          final genre =
              displayGenres[index]; // genre có thể là Genre hoặc String
          bool isSelected =
              context.watch<MovieProvider>().selectedGenreIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: ChoiceChip(
              label: Text(genre.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  // Reset carousel về trang đầu tiên một cách trực quan
                  setState(() {
                    _actualMovieIndex = 0; // Reset chỉ số phim
                    _currentPage = 10000; // Reset trang của PageView
                  });
                  // Khởi tạo lại controller để reset hoàn toàn trạng thái của nó
                  _initializePageController();
                  // Gọi provider để cập nhật trạng thái và fetch dữ liệu mới
                  Provider.of<MovieProvider>(context, listen: false)
                      .selectGenre(index, genre.id);
                  // Khởi động lại timer
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

  // Widget cho hiệu ứng "Worm" (con sâu)
  Widget _buildWormIndicator(
      {required int itemCount, required int activeIndex}) {
    if (itemCount == 0) return const SizedBox.shrink();

    const double dotSize = 8.0;
    const double dotSpacing = 12.0; // Khoảng cách giữa các chấm

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Lớp nền: các chấm không hoạt động
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
        // Lớp trên: "con sâu" di chuyển
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
