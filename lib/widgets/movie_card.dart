import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/api_constants.dart';
import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;

  const MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/movie/${movie.id}');
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: movie.posterPath != null
            ? CachedNetworkImage(
                imageUrl: '${ApiConstants.imageBaseUrl}${movie.posterPath}',
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Center(child: Icon(Icons.movie)),
              )
            : const Center(child: Icon(Icons.movie)),
      ),
    );
  }
}
