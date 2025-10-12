import 'package:flutter/material.dart';
import '../models/movie.dart';
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
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                child: MovieCard(movie: movie),
              );
            },
          ),
        ),
      ],
    );
  }
}
