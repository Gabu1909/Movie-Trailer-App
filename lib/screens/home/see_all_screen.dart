import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_constants.dart';
import '../../models/movie.dart';
import '../../models/cast.dart';
import '../../widgets/common/movie_grid_view.dart';

class SeeAllScreen extends StatelessWidget {
  final String title;
  final List<Movie>? movies;
  final List<Cast>? cast; // Sửa thành List<Cast> để đảm bảo kiểu dữ liệu

  const SeeAllScreen({
    super.key,
    required this.title,
    this.movies,
    this.cast,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _buildGrid(),
    );
  }

  Widget _buildGrid() {
    if (movies != null && movies!.isNotEmpty) {
      // Use reusable MovieGridView widget
      return MovieGridView(movies: movies!);
    } else if (cast != null && cast!.isNotEmpty) {
      // Hiển thị Grid cho diễn viên
      return GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Hiển thị 3 diễn viên mỗi hàng
          childAspectRatio: 3 / 4.5, // Tỷ lệ cho ảnh và tên
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: cast!.length,
        itemBuilder: (context, index) {
          final actor = cast![index];
          return _buildCastGridItem(context, actor);
        },
      );
    } else {
      return const Center(child: Text('No items to display.'));
    }
  }

  // Widget riêng để hiển thị một diễn viên trong grid
  Widget _buildCastGridItem(BuildContext context, Cast cast) {
    return GestureDetector(
      onTap: () {
        context.push('/actor/${cast.id}');
      },
      child: Column(
        children: [
          Expanded(
            child: CircleAvatar(
              radius: 50, // Kích thước lớn hơn
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
