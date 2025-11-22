import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/movie.dart';
import '../../../core/services/feedback_service.dart';

class TrailerCard extends StatelessWidget {
  final Video video;

  const TrailerCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    
    final String thumbnailUrl =
        'https://img.youtube.com/vi/${video.key}/mqdefault.jpg';

    return GestureDetector(
      onTap: () {
        FeedbackService.lightImpact(context);
        context.push(
          '/play-youtube/${video.key}',
          extra: {'title': video.name},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 90, 
        child: Row(
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFF251642)),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.movie_creation_outlined,
                            color: Colors.white24),
                      ),
                    ),
                    Container(
                      decoration:
                          BoxDecoration(color: Colors.black.withOpacity(0.2)),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Video Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    video.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video.type,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
