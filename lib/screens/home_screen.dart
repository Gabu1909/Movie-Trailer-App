import 'dart:ui';
import 'dart:async'; // Import để sử dụng Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_list.dart';
import '../widgets/trending_movie_card.dart'; // Import widget mới
import '../widgets/trending_movie_card_placeholder.dart'; // Import placeholder
import '../widgets/custom_app_bar.dart'; // Import CustomAppBar
import '../theme/constants.dart';
import '../models/genre.dart';
import 'see_all_screen.dart'; // Import SeeAllScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  PageController? _pageController; // Chuyển thành biến có thể null
  int _currentPage = 10000; // Trang hiện tại của PageView (trong dải vô hạn)
  int _actualMovieIndex = 0; // Chỉ số thực của phim trong danh sách
  Timer? _autoSlideTimer; // Khai báo biến timer

  // Key để điều khiển drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Biến cho hover effect trên genre chips
  int? _hoveredGenreId;

  // Các biến cho hiệu ứng nền mới
  late AnimationController _bgController;
  late Animation<Alignment> _beginAlignmentAnimation;
  late Animation<Alignment> _endAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Tăng thời gian để chậm hơn
    )..repeat(reverse: true);

    // Tạo hiệu ứng chuyển động cho điểm bắt đầu và kết thúc của gradient
    _beginAlignmentAnimation =
        AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight)
            .animate(_bgController);
    _endAlignmentAnimation =
        AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft)
            .animate(_bgController);

    // Khởi tạo controller và bắt đầu timer
    _initializePageController();
    _startAutoSlideTimer();
  }

  // Hàm để khởi tạo hoặc khởi tạo lại PageController
  void _initializePageController() {
    // Hủy controller cũ nếu có
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

  // Hàm để bắt đầu timer
  void _startAutoSlideTimer() {
    // Hủy timer cũ nếu có để tránh chạy nhiều timer cùng lúc
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController?.hasClients ?? false) {
        final movieProvider =
            Provider.of<MovieProvider>(context, listen: false);
        if (movieProvider.trendingMovies.isEmpty) return;
        _pageController!.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic, // Thay đổi hiệu ứng chuyển động
        );
      }
    });
  }

  // Hàm để dừng timer
  void _stopAutoSlideTimer() {
    _autoSlideTimer?.cancel();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pageController?.dispose(); // Hủy controller nếu nó tồn tại
    _autoSlideTimer?.cancel(); // Hủy timer khi widget bị dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(context),
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

  // Widget cho Drawer menu
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

          // Feature Film (Phim Lẻ - chỉ movies, không có TV shows)
          ListTile(
            leading: const Icon(Icons.movie_filter, color: Colors.white70),
            title: const Text('Feature Films',
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              final provider = context.read<MovieProvider>();
              provider.clearDrawerGenres();

              // Close drawer
              Navigator.of(context).pop();

              // Đợi drawer đóng xong
              await Future.delayed(const Duration(milliseconds: 300));

              if (!context.mounted) return;

              // Đợi initialization complete nếu chưa xong
              await provider.initializationComplete;

              if (!context.mounted) return;

              // popularMovies đã chỉ chứa movies (từ /movie/popular endpoint)
              final movies = provider.popularMovies;
              print(
                  'DEBUG: Feature Films - got ${movies.length} movies (movies only, no TV)');

              if (movies.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No movies found')),
                  );
                }
                return;
              }

              if (context.mounted) {
                context.push('/see-all',
                    extra: {'title': 'Feature Films', 'movies': movies});
              }
            },
          ), // TV Shows
          ListTile(
            leading: const Icon(Icons.tv, color: Colors.white70),
            title:
                const Text('TV Shows', style: TextStyle(color: Colors.white)),
            onTap: () async {
              final provider = context.read<MovieProvider>();
              provider.clearDrawerGenres();

              // Close drawer
              Navigator.of(context).pop();

              // Đợi drawer đóng xong
              await Future.delayed(const Duration(milliseconds: 300));

              if (!context.mounted) return;

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => const Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent),
                ),
              );

              try {
                print('DEBUG: Fetching TV shows...');
                final tvShows = await provider.getPopularTVShows();
                print('DEBUG: Got ${tvShows.length} TV shows');

                if (!context.mounted) return;

                // Close loading với rootNavigator
                Navigator.of(context, rootNavigator: true).pop();

                if (tvShows.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No TV shows found')),
                    );
                  }
                  return;
                }

                if (context.mounted) {
                  context.push('/see-all',
                      extra: {'title': 'TV Shows', 'movies': tvShows});
                }
              } catch (e) {
                print('ERROR fetching TV shows: $e');
                if (!context.mounted) return;
                Navigator.of(context, rootNavigator: true).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error loading TV shows: $e')),
                );
              }
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
                      print('🎯 Apply Filters button pressed');

                      final movieProvider =
                          Provider.of<MovieProvider>(context, listen: false);
                      final navigator =
                          Navigator.of(context, rootNavigator: true);

                      // Close drawer
                      Navigator.of(context).pop();
                      print('✅ Drawer closed');

                      // ĐỢI drawer đóng hoàn toàn
                      await Future.delayed(const Duration(milliseconds: 300));

                      print('🔍 Starting to fetch movies...');
                      print(
                          '📊 Selected genres: ${movieProvider.selectedDrawerGenreIds}');
                      print(
                          '🌍 Selected countries: ${movieProvider.selectedCountries}');

                      try {
                        // Fetch movies
                        final movies = await movieProvider.getMoviesByFilter();
                        final title = movieProvider.getSelectedGenresText();

                        print('✅ Fetched ${movies.length} movies');
                        print('📝 Title: $title');

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

                        // Navigate NGAY - dùng navigator đã lưu từ đầu
                        print(
                            '🚀 Navigating to /see-all with ${movies.length} movies');
                        print('🎬 First movie: ${movies.first.title}');

                        navigator.push(
                          MaterialPageRoute(
                            builder: (context) => SeeAllScreen(
                              title: title,
                              movies: movies,
                            ),
                          ),
                        );

                        print('✅ Navigation completed');
                      } catch (e) {
                        print('❌ ERROR applying filters: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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

  // Widget cho toàn bộ phần "Trending" (Carousel + Tabs)
  Widget _buildTrendingSection(BuildContext context, MovieProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề "Lets Explore" và "Trending"
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
                              Icons.trending_up_rounded, // Icon giống mũi tên
                              color: kGreyColor,
                              size: 20,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push('/see-all', extra: {
                        'title': 'Trending',
                        'movies': provider
                            .trendingMovies // Dùng danh sách trending hiện tại
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

        // Các tab thể loại (Genre)
        _buildGenreTabs(context, provider.genres),

        // Carousel (PageView) + overlay indicator
        SizedBox(
          height: 380,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                // Nâng cấp: Sử dụng cross-fade để chuyển đổi mượt mà hơn
                // giữa shimmer và danh sách phim.
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
            padding: const EdgeInsets.only(right: 12.0),
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
