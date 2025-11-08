import 'dart:ui';
import 'dart:async'; // Import để sử dụng Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // Thêm import cho SystemSound
import 'package:go_router/go_router.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_list.dart';
import '../widgets/trending_movie_card.dart'; // Import widget mới
import '../widgets/trending_movie_card_placeholder.dart'; // Import placeholder
import '../widgets/movie_list_placeholder.dart'; // Import placeholder mới
import '../theme/constants.dart';
import '../providers/notification_provider.dart'; // Import NotificationProvider
import '../models/genre.dart';
import 'feedback_service.dart'; // Import service mới

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
          return RefreshIndicator(
            onRefresh: () => provider.fetchAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: provider.isLoading
                    ? [
                        // Hiển thị khi đang tải dữ liệu lần đầu
                        _buildCustomAppBar(context),
                        _buildTrendingSection(
                            context, provider), // Trending có shimmer riêng
                        const MovieListPlaceholder(),
                        const MovieListPlaceholder(),
                        const MovieListPlaceholder(),
                      ]
                    : [
                        // Hiển thị khi đã có dữ liệu
                        _buildCustomAppBar(context),
                        _buildTrendingSection(context, provider),
                        if (provider.upcomingMovies.isNotEmpty)
                          MovieList(
                              title: 'COMING SOON',
                              movies: provider.upcomingMovies),
                        if (provider.kidsMovies.isNotEmpty)
                          MovieList(
                              title: 'BEST FOR KIDS',
                              movies: provider.kidsMovies),
                        if (provider.topRatedMovies.isNotEmpty)
                          MovieList(
                              title: 'TOP RATED',
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

  // Widget cho thanh AppBar tùy chỉnh
  Widget _buildCustomAppBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10, width: 1),
                  ),
                  child: Row(
                    children: [
                      // vòng hồng nhỏ chứa icon search — giống mẫu
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: kPrimaryColor, // màu hồng chủ đạo
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.28),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.search,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: kGreyColor.withOpacity(0.9),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.08), // Tăng độ trong suốt một chút
                borderRadius: BorderRadius.circular(12),
              ),
              child: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  final unreadCount = notificationProvider.unreadCount;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white70),
                        onPressed: () {
                          FeedbackService.playSound(context);
                          FeedbackService.lightImpact(context);
                          context.push('/notifications');
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
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
                  FeedbackService.playSound(context);
                  FeedbackService.lightImpact(context);
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
