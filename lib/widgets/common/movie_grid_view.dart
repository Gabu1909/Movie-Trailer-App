import 'package:flutter/material.dart';
import '../../models/movie.dart';
import '../cards/movie_card.dart';

/// Reusable GridView widget for displaying movies
///
/// Usage:
/// ```dart
/// MovieGridView(movies: movieList)
/// ```
class MovieGridView extends StatelessWidget {
  final List<Movie> movies;
  final EdgeInsets? padding;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const MovieGridView({
    super.key,
    required this.movies,
    this.padding,
    this.crossAxisCount = 2,
    this.childAspectRatio = 140 / 200,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return MovieCard(movie: movie);
      },
    );
  }
}

/// Sliver version of MovieGridView for use in CustomScrollView
class SliverMovieGrid extends StatelessWidget {
  final List<Movie> movies;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const SliverMovieGrid({
    super.key,
    required this.movies,
    this.crossAxisCount = 2,
    this.childAspectRatio = 140 / 200,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final movie = movies[index];
          return MovieCard(movie: movie);
        },
        childCount: movies.length,
      ),
    );
  }
}
