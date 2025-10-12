import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF212529),
              ),
              child: Row(
                children: [
                  Image.asset('assets/logo.png', height: 40),
                  const SizedBox(width: 10),
                  const Text(
                    'PuTa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.category,
              title: 'Genres',
              onTap: () {},
            ),
            _buildDrawerItem(
              icon: Icons.movie,
              title: 'Movies',
              onTap: () {},
            ),
            _buildDrawerItem(
              icon: Icons.tv,
              title: 'TV Shows',
              onTap: () {},
            ),
            _buildDrawerItem(
              icon: Icons.public,
              title: 'Countries',
              onTap: () {},
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 35),
            const SizedBox(width: 8),
            const Text('PuTa'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Consumer<MovieProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.popularMovies.isNotEmpty)
                    MovieList(title: 'Popular', movies: provider.popularMovies),
                  if (provider.nowPlayingMovies.isNotEmpty)
                    MovieList(
                        title: 'Now Playing',
                        movies: provider.nowPlayingMovies),
                  if (provider.topRatedMovies.isNotEmpty)
                    MovieList(
                        title: 'Top Rated', movies: provider.topRatedMovies),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
