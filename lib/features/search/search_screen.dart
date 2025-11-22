import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/models/cast.dart';
import '../../../core/models/movie.dart';
import '../../providers/search_provider.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_spacing.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounce;
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocus);
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final searchText = _searchController.text;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        try {
          context.read<SearchProvider>().search(searchText);
        } catch (e) {
          debugPrint('Provider error: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            gradient: Theme.of(context).brightness == Brightness.dark
                ? const LinearGradient(
                    colors: [
                        Color(0xFF0D0221),
                        Color(0xFF240046),
                        Color(0xFF150E28)
                      ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),

              _buildModernTabBar(),

              Expanded(
                child: Consumer<SearchProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) return _buildLoadingIndicator();

                    if (provider.query.isEmpty) return _buildInitialState();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        provider.movies.isEmpty
                            ? _buildEmptyState(
                                'No movies found', Icons.movie_filter_outlined)
                            : _buildMovieGrid(provider.movies),
                        provider.actors.isEmpty
                            ? _buildEmptyState(
                                'No actors found', Icons.person_off_outlined)
                            : _buildActorList(provider.actors),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
                cursorColor: const Color(0xFFFF006E), 
                decoration: InputDecoration(
                  hintText: 'Search for movies, actors...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Colors.white.withOpacity(0.5)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            context.read<SearchProvider>().clearResults();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          context
              .read<SearchProvider>()
              .setSearchType(index == 0 ? SearchType.movie : SearchType.person);
        },
        indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF006E), Color(0xFFFF6EC7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF006E).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 2),
              )
            ]),
        indicatorSize: TabBarIndicatorSize.tab, 
        dividerColor: Colors.transparent, 
        labelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(text: 'Movies'),
          Tab(text: 'Actors'),
        ],
      ),
    );
  }

  Widget _buildMovieGrid(List<Movie> movies) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.52,
        crossAxisSpacing: 12,
        mainAxisSpacing: 20,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return GestureDetector(
          onTap: () {
            FeedbackService.lightImpact(context);
            if (movie.mediaType == 'tv') {
              context.push(
                '/tv/${movie.id}',
                extra: {'heroTag': 'search-tv-${movie.id}'},
              );
            } else {
              context.push(
                '/movie/${movie.id}',
                extra: {'heroTag': 'search-${movie.id}'},
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: movie.posterPath != null
                        ? CachedNetworkImage(
                            imageUrl:
                                '${ApiConstants.imageBaseUrlW500}${movie.posterPath}',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: const Color(0xFF251642),
                              highlightColor: const Color(0xFF3A0CA3),
                              child: Container(color: const Color(0xFF251642)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF251642),
                                    const Color(0xFF3A0CA3).withOpacity(0.5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.movie_filter_rounded,
                                    color: Colors.white24, size: 40),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF251642),
                                  const Color(0xFF3A0CA3).withOpacity(0.5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.movie_filter_rounded,
                                  color: Colors.white24, size: 40),
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                height:
                    34, 
                child: Text(
                  movie.title,
                  maxLines: 2, 
                  overflow:
                      TextOverflow.ellipsis, 
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5, 
                    fontWeight: FontWeight.w600,
                    height: 1.2, 
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    movie.voteAverage.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),

                  const Spacer(), 

                  if (movie.releaseDate != null)
                    Text(
                      movie.releaseDate!.toString().split('-')[0],
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10, 
                          fontWeight: FontWeight.w500),
                    ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildActorList(List<Cast> actors) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (ctx, index) => const SizedBox(height: 12),
      itemCount: actors.length,
      itemBuilder: (context, index) {
        final actor = actors[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            onTap: () {
              FeedbackService.lightImpact(context);
              context.push('/actor/${actor.id}', extra: actor);
            },
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white10,
              backgroundImage: actor.profilePath != null
                  ? CachedNetworkImageProvider(
                      '${ApiConstants.imageBaseUrl}${actor.profilePath}')
                  : null,
              child: actor.profilePath == null
                  ? const Icon(Icons.person, color: Colors.white54)
                  : null,
            ),
            title: Text(
              actor.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            subtitle: Text(
              actor.knownForDepartment ?? 'Acting',
              style: TextStyle(
                  color: Colors.pinkAccent.withOpacity(0.8), fontSize: 13),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white30, size: 14),
          ),
        );
      },
    );
  }

  Widget _buildInitialState() {
    final keywords = [
      'Marvel',
      'Avatar',
      'Comedy',
      'Romance',
      'Horror',
      'Anime',
      'Action'
    ];
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search_rounded,
                size: 80, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            const Text("What are you looking for?",
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: keywords
                  .map((key) => ActionChip(
                        backgroundColor: Colors.white.withOpacity(0.08),
                        label: Text(key,
                            style: const TextStyle(color: Colors.white)),
                        onPressed: () {
                          _searchController.text = key;
                        },
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() =>
      const Center(child: CircularProgressIndicator(color: Color(0xFFFF006E)));

  Widget _buildEmptyState(String msg, IconData icon) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 60, color: Colors.white24),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(color: Colors.white54))
      ]));
}
