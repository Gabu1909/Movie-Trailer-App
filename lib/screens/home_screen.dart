// lib/screens/home_screen.dart
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
      // Drawer (Menu 3 gạch)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF212529), // Màu nền tối
              ),
              child: Row(
                children: [
                  // Thay 'assets/logo.png' bằng đường dẫn đến logo của bạn
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
            // Các mục trong menu
            _buildDrawerItem(
              icon: Icons.category,
              title: 'Thể Loại',
              onTap: () {
                // Thêm hành động khi nhấn vào đây, ví dụ: Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.movie,
              title: 'Phim Lẻ',
              onTap: () {},
            ),
            _buildDrawerItem(
              icon: Icons.tv,
              title: 'Phim Bộ',
              onTap: () {},
            ),
            _buildDrawerItem(
              icon: Icons.public,
              title: 'Quốc Gia',
              onTap: () {},
            ),
          ],
        ),
      ),
      // AppBar được thiết kế lại
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529), // Màu nền tối
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Thay 'assets/logo.png' bằng đường dẫn đến logo của bạn
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

  // Widget phụ để tạo các mục trong Drawer cho đẹp và gọn
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
