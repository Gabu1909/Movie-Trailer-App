import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_constants.dart';
import '../../models/movie.dart';
import '../../models/cast.dart'; // Import Video model
// Import widget RankedMovieCard xịn xò của bạn
import '../../services/feedback_service.dart';
import '../../widgets/cards/trailer_card.dart';

class SeeAllScreen extends StatelessWidget {
  final String title;
  final List<Movie>? movies;
  final List<Cast>? cast;

  const SeeAllScreen({
    super.key,
    required this.title,
    this.movies,
    this.cast,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Mở rộng body lên cả AppBar để nền gradient đẹp hơn
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent, // Trong suốt
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            gradient: Theme.of(context).brightness == Brightness.dark
                ? const LinearGradient(
                    colors: [
                        Color(0xFF0D0221),
                        Color(0xFF240046),
                        Color(0xFF3A0CA3),
                      ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (movies != null && movies!.isNotEmpty) {
      return _buildMovieGrid(); // Thay đổi để hiển thị lưới phim
    } else if (cast != null && cast!.isNotEmpty) {
      return _buildCastGrid();
    } else {
      return const Center(
        child: Text(
          'No items to display.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
  }

  // Widget mới để hiển thị lưới phim, giống màn hình Search
  Widget _buildMovieGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.52,
        crossAxisSpacing: 12,
        mainAxisSpacing: 20,
      ),
      itemCount: movies!.length,
      itemBuilder: (context, index) {
        final movie = movies![index];
        return GestureDetector(
          onTap: () {
            FeedbackService.lightImpact(context);
            context.push('/movie/${movie.id}');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: movie.posterPath != null
                        ? CachedNetworkImage(
                            imageUrl:
                                '${ApiConstants.imageBaseUrlW500}${movie.posterPath}',
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: const Color(0xFF251642)),
                            errorWidget: (context, url, error) => const Center(
                                child:
                                    Icon(Icons.movie, color: Colors.white24)),
                          )
                        : Container(
                            color: Colors.grey[900],
                            child:
                                const Icon(Icons.movie, color: Colors.white24)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tên phim
              SizedBox(
                height: 34,
                child: Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Rating
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    movie.voteAverage.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // Grid cho diễn viên (Làm đẹp thêm chút xíu)
  Widget _buildCastGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7, // Tinh chỉnh tỷ lệ
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: cast!.length,
      itemBuilder: (context, index) {
        final actor = cast![index];
        return _buildCastGridItem(context, actor);
      },
    );
  }

  Widget _buildCastGridItem(BuildContext context, Cast cast) {
    return GestureDetector(
      onTap: () {
        context.push('/actor/${cast.id}');
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.pinkAccent.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.2),
                    blurRadius: 10,
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white10,
                backgroundImage: cast.profilePath != null
                    ? CachedNetworkImageProvider(
                        '${ApiConstants.imageBaseUrl}${cast.profilePath}')
                    : null,
                child: cast.profilePath == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white54)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cast.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
