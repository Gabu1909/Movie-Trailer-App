import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/api_constants.dart';
import '../models/genre.dart';
import '../models/movie.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/custom_app_bar.dart';

class SeeAllScreen extends StatefulWidget {
  final String title;
  final List<Movie>? movies;
  final List<Cast>? cast;

  const SeeAllScreen({super.key, required this.title, this.movies, this.cast});

  @override
  State<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<SeeAllScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _hoveredGenreId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(onMenuPressed: () {
        _scaffoldKey.currentState?.openDrawer();
      }),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF12002F), Color(0xFF3A0CA3), Color(0xFF7209B7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(child: _buildGrid()),
          ],
        ),
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

              context.go('/see-all', extra: {
                'title': 'Feature films',
                'movies': provider.popularMovies
              });
            },
          ),

          // TV Shows - Simple button (không có Switch)
          ListTile(
            leading: const Icon(Icons.tv, color: Colors.white70),
            title:
                const Text('TV Shows', style: TextStyle(color: Colors.white)),
            onTap: () async {
              final provider = context.read<MovieProvider>();
              provider.clearDrawerGenres();

              final tvShows = await provider.getPopularTVShows();

              if (!context.mounted) return;
              context.go('/see-all',
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

          // Apply Filters Button - Đậm màu khi có filters
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
                      context.go('/see-all',
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

  Widget _buildGrid() {
    if (widget.movies != null && widget.movies!.isNotEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: widget.movies!.length,
        itemBuilder: (context, index) {
          final movie = widget.movies![index];
          return MovieCard(movie: movie);
        },
      );
    } else if (widget.cast != null && widget.cast!.isNotEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 3 / 4.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: widget.cast!.length,
        itemBuilder: (context, index) {
          final actor = widget.cast![index];
          return _buildCastGridItem(context, actor);
        },
      );
    } else {
      return const Center(
          child: Text('No items to display.',
              style: TextStyle(color: Colors.white)));
    }
  }

  Widget _buildCastGridItem(BuildContext context, Cast cast) {
    return GestureDetector(
      onTap: () {
        context.push('/actor/${cast.id}');
      },
      child: Column(
        children: [
          Expanded(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: cast.profilePath != null
                  ? CachedNetworkImageProvider(
                      '${ApiConstants.imageBaseUrl}${cast.profilePath}')
                  : null,
              child: cast.profilePath == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cast.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
