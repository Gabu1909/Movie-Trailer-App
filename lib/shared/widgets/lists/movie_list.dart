import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/movie.dart';
import '../cards/movie_card.dart'; 

class MovieList extends StatefulWidget {
  final String title;
  final List<Movie> movies;

  const MovieList({
    super.key,
    required this.title,
    required this.movies,
  });

  @override
  State<MovieList> createState() => _MovieListState();
}

class _MovieListState extends State<MovieList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title,
                    style: Theme.of(context).textTheme.headlineSmall),
                GestureDetector(
                  onTap: () => context.push('/see-all',
                      extra: {'title': widget.title, 'movies': widget.movies}),
                  child: Text('See All',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Builder(builder: (builderContext) {
              return ListView.builder(
                controller: _scrollController, 
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: widget.movies.length,
                itemBuilder: (context, index) {
                  double scrollOffset = 0.0;
                  if (_scrollController.hasClients &&
                      _scrollController.position.hasContentDimensions) {
                    final RenderBox? renderBox =
                        builderContext.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      final viewportWidth = renderBox.size.width;
                      const itemWidth =
                          140.0 + 12.0; 
                      final itemCenter = (index * itemWidth) + (itemWidth / 2);
                      final viewportCenter =
                          _scrollController.offset + (viewportWidth / 2);
                      scrollOffset = (itemCenter - viewportCenter) /
                          viewportWidth; 
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(
                        right: 16.0), 
                    child: MovieCard(
                        movie: widget.movies[index],
                        scrollOffset: scrollOffset),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
