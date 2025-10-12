import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  void _onSearch(BuildContext context) {
    final query = _controller.text;
    if (query.isNotEmpty) {
      Provider.of<MovieProvider>(context, listen: false).searchMovies(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Movies'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter movie title',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _onSearch(context),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _onSearch(context),
            ),
          ),
          Expanded(
            child: Consumer<MovieProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.searchedMovies.isEmpty &&
                    _controller.text.isNotEmpty) {
                  return const Center(child: Text('No results found.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2 / 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: provider.searchedMovies.length,
                  itemBuilder: (context, index) {
                    final movie = provider.searchedMovies[index];
                    return MovieCard(movie: movie);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
