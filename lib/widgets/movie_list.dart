import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/movie.dart';
import '../theme/constants.dart';
import 'movie_card.dart';

class MovieList extends StatelessWidget {
  final String title;
  final List<Movie> movies;

  const MovieList({super.key, required this.title, required this.movies});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 24, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: Colors.white.withOpacity(0.05),
                    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.push('/see-all',
                      extra: {'title': title, 'movies': movies});
                },
                child: Text(
                  'See All',
                  style: Theme.of(context).textTheme.bodyMedium, // Màu xám
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220, // Chiều cao cho poster dọc (tỷ lệ 2:3)
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Container(
                width: 140, // Chiều rộng cho poster
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                // Dùng MovieCard (sẽ được bo góc bằng CardTheme)
                child: MovieCard(movie: movie),
              );
            },
          ),
        ),
      ],
    );
  }
}
