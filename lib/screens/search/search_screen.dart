import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../api/api_constants.dart';
import '../../models/cast.dart';
import '../../models/movie.dart';
import '../../providers/search_provider.dart';
import '../../services/feedback_service.dart';
import '../../theme/app_spacing.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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
          // Provider might not be available if widget is being disposed
          debugPrint('SearchProvider not available: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF150E28),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: _buildSearchBar(),
          bottom: TabBar(
            indicatorColor: Colors.pinkAccent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            onTap: (index) {
              context.read<SearchProvider>().setSearchType(
                  index == 0 ? SearchType.movie : SearchType.person);
            },
            tabs: const [
              Tab(text: 'Movies'),
              Tab(text: 'Actors'),
            ],
          ),
        ),
        body: Consumer<SearchProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return _buildLoadingIndicator();
            }

            if (provider.query.isEmpty) {
              return _buildInitialState();
            }

            if (provider.searchType == SearchType.movie &&
                provider.movies.isEmpty) {
              return _buildEmptyState(
                  'No movies found for "${provider.query}"');
            }

            if (provider.searchType == SearchType.person &&
                provider.actors.isEmpty) {
              return _buildEmptyState(
                  'No actors found for "${provider.query}"');
            }

            return TabBarView(
              children: [
                _buildMovieResults(provider.movies),
                _buildActorResults(provider.actors),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search movies or actors...',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        border: InputBorder.none,
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white70),
                onPressed: () => _searchController.clear(),
              )
            : null,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return GridView.builder(
      padding: AppSpacing.paddingAll16,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[850]!,
          highlightColor: Colors.grey[800]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppSpacing.radius12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_filter_outlined,
              color: Colors.white38, size: 80),
          AppSpacing.height16,
          const Text(
            'Start typing to find your favorite movies and actors.',
            style: TextStyle(color: Colors.white60, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: Colors.white38, size: 80),
          AppSpacing.height16,
          Text(
            message,
            style: const TextStyle(color: Colors.white60, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMovieResults(List<Movie> movies) {
    return GridView.builder(
      padding: AppSpacing.paddingAll16,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return GestureDetector(
          onTap: () {
            FeedbackService.lightImpact(context);
            context.push('/movie/${movie.id}');
          },
          child: ClipRRect(
            borderRadius: AppSpacing.radius12,
            child: movie.posterPath != null
                ? CachedNetworkImage(
                    imageUrl: '${ApiConstants.imageBaseUrl}${movie.posterPath}',
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[850]),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.movie, color: Colors.white38),
                  )
                : Container(
                    color: Colors.grey[850],
                    child: const Icon(Icons.movie, color: Colors.white38),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildActorResults(List<Cast> actors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: actors.length,
      itemBuilder: (context, index) {
        final actor = actors[index];
        return Card(
          color: Colors.white.withOpacity(0.1),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () {
              FeedbackService.lightImpact(context);
              context.push('/actor/${actor.id}', extra: actor);
            },
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: actor.profilePath != null
                  ? CachedNetworkImageProvider(
                      '${ApiConstants.imageBaseUrl}${actor.profilePath}')
                  : null,
              child: actor.profilePath == null
                  ? const Icon(Icons.person, color: Colors.white70)
                  : null,
            ),
            title: Text(
              actor.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Known for: ${actor.knownForDepartment ?? 'Acting'}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
          ),
        );
      },
    );
  }
}

extension CastExtension on Cast {
  String? get knownForDepartment {
    if (knownFor == null || knownFor!.isEmpty) return 'N/A';
    // Lấy tên phim/show nổi bật nhất
    final knownForTitles = knownFor!
        .map((e) => e['title'] ?? e['name'] as String?)
        .where((title) => title != null)
        .take(2)
        .join(', ');
    return knownForTitles.isNotEmpty ? knownForTitles : 'Acting';
  }
}
